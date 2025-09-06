//
//  ScreenTimeManager.swift - FIXED VERSION
//  screenstakeios
//

import Foundation
import FamilyControls
import DeviceActivity

@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isAuthorized = false
    
    private let authCenter = AuthorizationCenter.shared
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestScreenTimeAccess() async throws {
        print("📱 Requesting Screen Time access...")
        
        do {
            try await authCenter.requestAuthorization(for: .individual)
            await checkAuthorizationStatus()
            print("✅ Screen Time access granted")
        } catch {
            print("❌ Screen Time access denied: \(error)")
            throw ScreenTimeError.accessDenied
        }
    }
    
    private func checkAuthorizationStatus() {
        authorizationStatus = authCenter.authorizationStatus
        isAuthorized = authorizationStatus == .approved
        
        print("🔐 Screen Time authorization status: \(authorizationStatus)")
    }
    
    // MARK: - Real Usage Data
    func getRealUsageData(for date: Date = Date()) async -> [String: TimeInterval] {
        // For now, always use predictable mock data
        // In production, you would check isAuthorized and use real Screen Time API
        print("⚠️ Using predictable mock data for development")
        return generatePredictableMockUsage(for: date)
    }
    
    // FIXED: Generate predictable, time-based usage instead of random
    private func generatePredictableMockUsage(for date: Date) -> [String: TimeInterval] {
        var usage: [String: TimeInterval] = [:]
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let now = min(date, Date()) // Don't generate future usage
        
        // Calculate how much of the day has passed
        let hoursElapsed = now.timeIntervalSince(startOfDay) / 3600.0
        
        // Realistic usage patterns throughout the day
        for app in SocialApp.availableApps {
            let targetDailyUsage: TimeInterval
            
            // Set realistic daily usage targets for each app
            switch app.name {
            case "instagram":
                targetDailyUsage = 3600 // 1 hour per day
            case "tiktok":
                targetDailyUsage = 4800 // 1.33 hours per day
            case "youtube":
                targetDailyUsage = 5400 // 1.5 hours per day
            case "x":
                targetDailyUsage = 1800 // 30 minutes per day
            case "snapchat":
                targetDailyUsage = 2400 // 40 minutes per day
            default:
                targetDailyUsage = 1800 // 30 minutes default
            }
            
            // Calculate usage based on time progression through active hours (6am-10pm = 16 hours)
            let activeHoursElapsed = max(0, min(16, hoursElapsed - 6)) // Start counting from 6am
            let progressThroughActiveDay = max(0, min(1.0, activeHoursElapsed / 16.0))
            
            // Smooth curve - more usage in evening hours
            let usageCurve = pow(progressThroughActiveDay, 1.2)
            let currentUsage = targetDailyUsage * usageCurve
            
            usage[app.bundleIdentifier] = max(0, currentUsage)
        }
        
        return usage
    }
    
    // MARK: - Real Screen Time Integration (for future use)
    private func getRealScreenTimeData(for interval: DateInterval) async throws -> [String: TimeInterval] {
        // This is where you'd integrate with DeviceActivityReport
        // For now, throwing an error to fall back to mock data
        throw ScreenTimeError.dataUnavailable
    }
}

enum ScreenTimeError: LocalizedError {
    case accessDenied
    case dataUnavailable
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Screen Time access is required to track app usage"
        case .dataUnavailable:
            return "Screen Time data is not available"
        }
    }
}