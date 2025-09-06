//
//  StakeTrackingService.swift - FIXED VERSION
//  screenstakeios
//

import Foundation
import Combine
import UserNotifications

@MainActor
class StakeTrackingService: ObservableObject {
    static let shared = StakeTrackingService()
    
    @Published var currentDayUsage: [String: TimeInterval] = [:] // bundleId: seconds today
    @Published var isTrackingActive = false
    @Published var lastUpdateTime = Date()
    
    // FIXED: Add persistent state to prevent random jumps
    private var baseUsageData: [String: TimeInterval] = [:] // Persistent base usage
    private var lastResetDate = Date()
    
    private let persistenceManager = PersistenceManager.shared
    private let screenTimeManager = ScreenTimeManager.shared
    private var trackingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadPersistedUsageData()
        setupScreenTimeIntegration()
        startTracking()
        setupDayRollover()
    }
    
    // MARK: - Persistent Usage Data
    private func loadPersistedUsageData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we have data for today
        if let savedDate = UserDefaults.standard.object(forKey: "lastUsageDate") as? Date,
           calendar.isDate(savedDate, inSameDayAs: today) {
            
            // Load today's usage data
            for app in SocialApp.availableApps {
                let key = "usage_\(app.bundleIdentifier)"
                let usage = UserDefaults.standard.double(forKey: key)
                if usage > 0 {
                    baseUsageData[app.bundleIdentifier] = usage
                    currentDayUsage[app.bundleIdentifier] = usage
                }
            }
            
            lastResetDate = savedDate
            print("📊 Loaded persisted usage data for today")
        } else {
            // New day, start fresh
            resetDailyUsage()
        }
    }
    
    private func saveUsageData() {
        UserDefaults.standard.set(Date(), forKey: "lastUsageDate")
        
        for app in SocialApp.availableApps {
            let key = "usage_\(app.bundleIdentifier)"
            let usage = currentDayUsage[app.bundleIdentifier] ?? 0
            UserDefaults.standard.set(usage, forKey: key)
        }
    }
    
    // MARK: - Screen Time Integration
    private func setupScreenTimeIntegration() {
        Task {
            do {
                try await screenTimeManager.requestScreenTimeAccess()
                print("✅ Screen Time integration ready")
            } catch {
                print("⚠️ Screen Time unavailable, using controlled mock data: \(error)")
            }
        }
    }
    
    // MARK: - Tracking Management
    func startTracking() {
        print("🎯 Starting stake tracking service")
        isTrackingActive = true
        
        // Update every 60 seconds for real-time progress
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateUsageAndCheckStakes()
            }
        }
        
        // Immediate update
        Task {
            await updateUsageAndCheckStakes()
        }
    }
    
    func stopTracking() {
        print("⏹️ Stopping stake tracking service")
        isTrackingActive = false
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    // MARK: - Usage Updates
    private func updateUsageAndCheckStakes() async {
        print("📊 Updating usage data... (\(Date().formatted(date: .omitted, time: .shortened)))")
        
        // FIXED: Use predictable usage progression instead of random
        updatePredictableUsage()
        lastUpdateTime = Date()
        
        // Save to persistence
        saveUsageData()
        
        // Update all active stakes
        await updateActiveStakes()
        
        // Log current usage for debugging
        logCurrentUsage()
    }
    
    // FIXED: Predictable usage progression
    private func updatePredictableUsage() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        // Calculate hours elapsed today
        let hoursElapsed = now.timeIntervalSince(startOfDay) / 3600.0
        
        // Generate realistic but predictable usage based on time of day
        for app in SocialApp.availableApps {
            let baseUsage = baseUsageData[app.bundleIdentifier] ?? 0
            
            // Progressive usage throughout the day (not random)
            let expectedDailyUsage: TimeInterval
            switch app.name {
            case "instagram":
                expectedDailyUsage = 3600 // 1 hour per day
            case "tiktok":
                expectedDailyUsage = 4800 // 1.33 hours per day
            case "youtube":
                expectedDailyUsage = 5400 // 1.5 hours per day
            case "x":
                expectedDailyUsage = 1800 // 30 minutes per day
            case "snapchat":
                expectedDailyUsage = 2400 // 40 minutes per day
            default:
                expectedDailyUsage = 1800
            }
            
            // Smooth progression throughout the day
            let progressThroughDay = min(1.0, hoursElapsed / 16.0) // Active hours: 6am-10pm
            let targetUsage = expectedDailyUsage * progressThroughDay
            
            // Only increase usage, never decrease (unless it's a new day)
            let currentUsage = currentDayUsage[app.bundleIdentifier] ?? 0
            currentDayUsage[app.bundleIdentifier] = max(currentUsage, targetUsage)
            baseUsageData[app.bundleIdentifier] = currentDayUsage[app.bundleIdentifier] ?? 0
        }
    }
    
    private func updateActiveStakes() async {
        var stakes = persistenceManager.currentStakes
        var stakesUpdated = false
        
        for i in stakes.indices {
            guard stakes[i].isActive && stakes[i].status == .active else { continue }
            
            let oldStake = stakes[i]
            
            // FIXED: Better new day detection
            if shouldResetStakeUsage(stake: oldStake) {
                print("🌅 New day detected, resetting daily usage for stake: \(oldStake.id)")
                stakes[i].currentUsage = 0
                stakesUpdated = true
            }
            
            // Update current usage for this stake
            let newUsage = calculateStakeUsage(for: oldStake)
            let previousUsage = stakes[i].currentUsage
            stakes[i].currentUsage = newUsage
            stakes[i].lastUpdated = Date()
            
            // FIXED: Only update if usage actually changed significantly
            if abs(newUsage - previousUsage) > 30 { // 30 second threshold
                stakesUpdated = true
            }
            
            // Auto-complete expired stakes
            if oldStake.shouldComplete {
                print("✅ Auto-completing expired stake: \(oldStake.id)")
                stakes[i].status = .completed
                stakes[i].isActive = false
                stakesUpdated = true
            }
            
            // FIXED: Better failure detection - only fail if significantly over limit
            else if newUsage > (oldStake.dailyTimeLimit + 300) && // 5 minute buffer
                    stakes[i].status == .active && 
                    !hasFailedToday(stake: oldStake) {
                
                print("❌ Stake failed - over limit: \(oldStake.id)")
                print("   Usage: \(formatTime(newUsage)), Limit: \(formatTime(oldStake.dailyTimeLimit))")
                
                // In production, this would trigger the payment
                await handleStakeFailure(stake: stakes[i])
                
                // Mark as failed for today
                stakes[i].status = .failed
                stakesUpdated = true
            }
        }
        
        if stakesUpdated {
            persistenceManager.currentStakes = stakes
            persistenceManager.saveStakes()
            print("💾 Stakes updated and saved")
        }
    }
    
    // FIXED: Better day detection
    private func shouldResetStakeUsage(stake: Stake) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let lastUpdate = stake.lastUpdated
        
        // Check if it's a new day
        let isNewDay = !calendar.isDate(lastUpdate, inSameDayAs: now)
        
        // Also check if our internal reset happened
        let wasReset = !calendar.isDate(lastResetDate, inSameDayAs: now)
        
        return isNewDay || wasReset
    }
    
    // MARK: - Failure Handling (unchanged)
    private func hasFailedToday(stake: Stake) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return stake.status == .failed && 
               calendar.isDate(stake.lastUpdated, inSameDayAs: today)
    }
    
    private func handleStakeFailure(stake: Stake) async {
        print("💳 Processing stake failure for: \(stake.id)")
        await sendLimitExceededNotification(stake: stake)
    }
    
    private func sendLimitExceededNotification(stake: Stake) async {
        let content = UNMutableNotificationContent()
        content.title = "Limit Exceeded! 💸"
        content.body = "You've exceeded your \(formatTime(stake.dailyTimeLimit)) limit. $\(Int(stake.stakeAmount)) stake triggered."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "stake_failed_\(stake.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Usage Calculations
    private func calculateStakeUsage(for stake: Stake) -> TimeInterval {
        var totalUsage: TimeInterval = 0
        
        for app in stake.selectedApps {
            let appUsage = currentDayUsage[app.bundleIdentifier] ?? 0
            totalUsage += appUsage
        }
        
        return totalUsage
    }
    
    // MARK: - Day Rollover
    private func setupDayRollover() {
        // Check for day rollover every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForDayRollover()
            }
        }
    }
    
    private func checkForDayRollover() async {
        let calendar = Calendar.current
        let now = Date()
        
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            print("🌅 New day detected - resetting all usage")
            resetDailyUsage()
            await updateUsageAndCheckStakes()
        }
    }
    
    private func resetDailyUsage() {
        currentDayUsage.removeAll()
        baseUsageData.removeAll()
        lastResetDate = Date()
        saveUsageData()
        print("🌅 Daily usage reset completed")
    }
    
    // MARK: - Public Methods
    func getUsageForApp(_ bundleId: String) -> TimeInterval {
        return currentDayUsage[bundleId] ?? 0
    }
    
    func getTotalUsageForStake(_ stake: Stake) -> TimeInterval {
        return calculateStakeUsage(for: stake)
    }
    
    func getFormattedUsageForStake(_ stake: Stake) -> String {
        let usage = getTotalUsageForStake(stake)
        return formatTime(usage)
    }
    
    // MARK: - FIXED Testing Methods
    func simulateTimePassage(hours: Double) {
        print("⏰ Simulating \(hours) hours passage...")
        
        // FIXED: Predictable usage increase instead of random
        for app in SocialApp.availableApps {
            let currentUsage = currentDayUsage[app.bundleIdentifier] ?? 0
            
            // Realistic usage per hour based on app type
            let usagePerHour: TimeInterval
            switch app.name {
            case "instagram", "tiktok":
                usagePerHour = 900 // 15 mins/hour average
            case "youtube":
                usagePerHour = 1200 // 20 mins/hour average
            case "x", "snapchat":
                usagePerHour = 600 // 10 mins/hour average
            default:
                usagePerHour = 450 // 7.5 mins/hour average
            }
            
            let additionalUsage = hours * usagePerHour
            let newUsage = currentUsage + additionalUsage
            
            currentDayUsage[app.bundleIdentifier] = newUsage
            baseUsageData[app.bundleIdentifier] = newUsage
        }
        
        // Save the simulated data
        saveUsageData()
        
        Task {
            await updateUsageAndCheckStakes()
        }
        
        print("✅ Time simulation complete - added \(hours) hours of usage")
    }
    
    // NEW: Reset usage for testing
    func resetUsageForTesting() {
        print("🧪 Resetting usage for testing")
        resetDailyUsage()
        
        Task {
            await updateUsageAndCheckStakes()
        }
    }
    
    // NEW: Set specific usage for testing
    func setUsageForTesting(app: SocialApp, minutes: Double) {
        let seconds = minutes * 60
        currentDayUsage[app.bundleIdentifier] = seconds
        baseUsageData[app.bundleIdentifier] = seconds
        saveUsageData()
        
        Task {
            await updateUsageAndCheckStakes()
        }
        
        print("🧪 Set \(app.displayName) usage to \(formatTime(seconds))")
    }
    
    // MARK: - Debugging
    private func logCurrentUsage() {
        print("📱 Current usage snapshot:")
        for app in SocialApp.availableApps {
            let usage = currentDayUsage[app.bundleIdentifier] ?? 0
            if usage > 0 {
                print("   \(app.displayName): \(formatTime(usage))")
            }
        }
    }
    
    // MARK: - Utilities
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    deinit {
        trackingTimer?.invalidate()
    }
}