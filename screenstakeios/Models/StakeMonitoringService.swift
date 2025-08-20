//
//  StakeMonitoringService.swift
//  screenstakeios
//
//  Monitors screen time and processes charges when limits are exceeded
//

import Foundation
import DeviceActivity
import FamilyControls
import UserNotifications

@MainActor
class StakeMonitoringService: ObservableObject {
    static let shared = StakeMonitoringService()
    
    @Published var todayUsage: [String: TimeInterval] = [:] // bundleId: seconds
    @Published var activeStakes: [Stake] = []
    @Published var chargeHistory: [ChargeRecord] = []
    
    private let paymentManager = StripePaymentManager.shared
    private let persistenceManager = PersistenceManager.shared
    private var monitoringTimer: Timer?
    
    private init() {
        setupMonitoring()
        loadActiveStakes()
    }
    
    // MARK: - Screen Time Monitoring
    private func setupMonitoring() {
        // Request authorization for Screen Time API
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                startMonitoring()
            } catch {
                print("Failed to authorize Screen Time: \(error)")
            }
        }
    }
    
    private func startMonitoring() {
        // Monitor every 5 minutes
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.checkUsageAndProcess()
            }
        }
    }
    
    // MARK: - Usage Checking
    @MainActor
    private func checkUsageAndProcess() async {
        // Get today's usage for monitored apps
        let usage = await fetchTodayUsage()
        
        // Check each active stake
        for stake in activeStakes {
            await processStake(stake, with: usage)
        }
    }
    
    private func fetchTodayUsage() async -> [String: TimeInterval] {
        // This would integrate with Screen Time API
        // For now, return mock data
        return todayUsage
    }
    
    // MARK: - Stake Processing
    private func processStake(_ stake: Stake, with usage: [String: TimeInterval]) async {
        // Calculate total usage for stake's apps
        let totalUsage = stake.selectedApps.reduce(0) { total, app in
            total + (usage[app.bundleIdentifier] ?? 0)
        }
        
        // Check if over limit
        if totalUsage > stake.dailyTimeLimit {
            // Check if already charged today
            if !hasChargedToday(for: stake) {
                await processCharge(for: stake, exceededBy: totalUsage - stake.dailyTimeLimit)
            }
        }
    }
    
    // MARK: - Charge Processing
    private func processCharge(for stake: Stake, exceededBy: TimeInterval) async {
        // Log the violation
        let violation = LimitViolation(
            stakeId: stake.id.uuidString,
            timestamp: Date(),
            exceededBy: exceededBy,
            totalUsage: stake.currentUsage,
            dailyLimit: stake.dailyTimeLimit
        )
        
        await logViolation(violation)
        
        // Get user's default payment method
        guard let userId = getCurrentUserId(),
              let paymentMethod = getDefaultPaymentMethod(for: userId) else {
            await sendPaymentMethodRequiredNotification()
            return
        }
        
        do {
            // Process the charge
            let chargeResult = try await paymentManager.chargeStakeAmount(
                userId: userId,
                paymentMethodId: paymentMethod.id,
                amount: stake.stakeAmount,
                stakeId: stake.id.uuidString
            )
            
            // Record successful charge
            let chargeRecord = ChargeRecord(
                id: chargeResult.chargeId,
                stakeId: stake.id.uuidString,
                amount: stake.stakeAmount,
                chargedAt: Date(),
                reason: "Daily limit exceeded by \(formatTime(exceededBy))",
                status: .succeeded,
                receiptUrl: chargeResult.receiptUrl
            )
            
            await saveChargeRecord(chargeRecord)
            await sendChargeNotification(chargeRecord)
            await sendReceiptEmail(chargeRecord)
            
        } catch PaymentError.authenticationRequired(let clientSecret) {
            // Requires 3DS authentication
            await handleAuthenticationRequired(clientSecret: clientSecret, stake: stake)
            
        } catch {
            // Log failed charge attempt
            let failedCharge = ChargeRecord(
                id: UUID().uuidString,
                stakeId: stake.id.uuidString,
                amount: stake.stakeAmount,
                chargedAt: Date(),
                reason: "Charge failed: \(error.localizedDescription)",
                status: .failed,
                receiptUrl: nil
            )
            
            await saveChargeRecord(failedCharge)
            await sendChargeFailedNotification(error: error)
        }
    }
    
    // MARK: - 3DS Authentication Handling
    private func handleAuthenticationRequired(clientSecret: String, stake: Stake) async {
        // Send push notification to complete authentication
        await sendAuthenticationRequiredNotification(for: stake)
        
        // Store pending charge for retry
        let pendingCharge = PendingCharge(
            stakeId: stake.id.uuidString,
            clientSecret: clientSecret,
            amount: stake.stakeAmount,
            createdAt: Date()
        )
        
        await savePendingCharge(pendingCharge)
    }
    
    // MARK: - Notifications
    private func sendChargeNotification(_ charge: ChargeRecord) async {
        let content = UNMutableNotificationContent()
        content.title = "Stake Charge Processed"
        content.body = "You exceeded your daily limit. $\(Int(charge.amount)) has been charged."
        content.sound = .default
        content.categoryIdentifier = "CHARGE_NOTIFICATION"
        
        // Add action buttons
        content.userInfo = [
            "chargeId": charge.id,
            "type": "charge_processed"
        ]
        
        let request = UNNotificationRequest(
            identifier: "charge_\(charge.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func sendAuthenticationRequiredNotification(for stake: Stake) async {
        let content = UNMutableNotificationContent()
        content.title = "Authentication Required"
        content.body = "Tap to complete payment authentication for your stake."
        content.sound = .default
        content.categoryIdentifier = "AUTH_REQUIRED"
        content.interruptionLevel = .timeSensitive
        
        content.userInfo = [
            "stakeId": stake.id.uuidString,
            "type": "authentication_required"
        ]
        
        let request = UNNotificationRequest(
            identifier: "auth_\(stake.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func sendPaymentMethodRequiredNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Payment Method Required"
        content.body = "Add a payment method to continue your stake."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "payment_required",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func sendChargeFailedNotification(error: Error) async {
        let content = UNMutableNotificationContent()
        content.title = "Charge Failed"
        content.body = "We couldn't process your stake charge. Please update your payment method."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "charge_failed",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Email Receipts
    private func sendReceiptEmail(_ charge: ChargeRecord) async {
        // Call backend to send email receipt
        let endpoint = "\(APIConfig.baseURL)/send-receipt"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "chargeId": charge.id,
            "email": getUserEmail() ?? "",
            "amount": charge.amount,
            "reason": charge.reason,
            "timestamp": ISO8601DateFormatter().string(from: charge.chargedAt)
        ] as [String : Any]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        _ = try? await URLSession.shared.data(for: request)
    }
    
    // MARK: - Dispute Handling
    func disputeCharge(_ chargeId: String, reason: String) async throws {
        // Within 24 hours, allow dispute
        guard let charge = chargeHistory.first(where: { $0.id == chargeId }),
              Date().timeIntervalSince(charge.chargedAt) < 86400 else {
            throw DisputeError.outsideDisputeWindow
        }
        
        let endpoint = "\(APIConfig.baseURL)/dispute-charge"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "chargeId": chargeId,
            "reason": reason,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DisputeError.disputeFailed
        }
        
        // Update local charge record
        if let index = chargeHistory.firstIndex(where: { $0.id == chargeId }) {
            chargeHistory[index].status = .disputed
        }
    }
    
    // MARK: - Helper Methods
    private func hasChargedToday(for stake: Stake) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return chargeHistory.contains { charge in
            charge.stakeId == stake.id.uuidString &&
            charge.status == .succeeded &&
            calendar.startOfDay(for: charge.chargedAt) == today
        }
    }
    
    private func loadActiveStakes() {
        activeStakes = persistenceManager.getActiveStakes()
    }
    
    private func getCurrentUserId() -> String? {
        // Get from auth manager
        return "current_user_id"
    }
    
    private func getUserEmail() -> String? {
        // Get from auth manager
        return "user@example.com"
    }
    
    private func getDefaultPaymentMethod(for userId: String) -> SavedPaymentMethod? {
        return paymentManager.savedPaymentMethods.first { $0.isDefault }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    // MARK: - Data Persistence
    private func logViolation(_ violation: LimitViolation) async {
        // Store violation record
        var violations = UserDefaults.standard.object(forKey: "violations") as? [[String: Any]] ?? []
        violations.append(violation.toDictionary())
        UserDefaults.standard.set(violations, forKey: "violations")
    }
    
    private func saveChargeRecord(_ record: ChargeRecord) async {
        chargeHistory.append(record)
        
        // Persist to storage
        if let encoded = try? JSONEncoder().encode(chargeHistory) {
            UserDefaults.standard.set(encoded, forKey: "charge_history")
        }
    }
    
    private func savePendingCharge(_ charge: PendingCharge) async {
        var pending = UserDefaults.standard.object(forKey: "pending_charges") as? [[String: Any]] ?? []
        pending.append(charge.toDictionary())
        UserDefaults.standard.set(pending, forKey: "pending_charges")
    }
}

// MARK: - Data Models
struct LimitViolation: Codable {
    let stakeId: String
    let timestamp: Date
    let exceededBy: TimeInterval
    let totalUsage: TimeInterval
    let dailyLimit: TimeInterval
    
    func toDictionary() -> [String: Any] {
        return [
            "stakeId": stakeId,
            "timestamp": timestamp,
            "exceededBy": exceededBy,
            "totalUsage": totalUsage,
            "dailyLimit": dailyLimit
        ]
    }
}

struct ChargeRecord: Codable, Identifiable {
    let id: String
    let stakeId: String
    let amount: Double
    let chargedAt: Date
    let reason: String
    var status: ChargeStatus
    let receiptUrl: String?
}

enum ChargeStatus: String, Codable {
    case pending
    case succeeded
    case failed
    case disputed
    case refunded
}

struct PendingCharge: Codable {
    let stakeId: String
    let clientSecret: String
    let amount: Double
    let createdAt: Date
    
    func toDictionary() -> [String: Any] {
        return [
            "stakeId": stakeId,
            "clientSecret": clientSecret,
            "amount": amount,
            "createdAt": createdAt
        ]
    }
}

enum DisputeError: LocalizedError {
    case outsideDisputeWindow
    case disputeFailed
    
    var errorDescription: String? {
        switch self {
        case .outsideDisputeWindow:
            return "Disputes must be submitted within 24 hours of the charge"
        case .disputeFailed:
            return "Failed to process dispute. Please try again."
        }
    }
}