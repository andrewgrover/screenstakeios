//
//  DataModels.swift - COMPLETE UPDATED VERSION
//  screenstakeios
//

import Foundation

// MARK: - App Selection Model
struct SocialApp: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let displayName: String
    let iconName: String
    let bundleIdentifier: String
    let color: String // Changed from Color to String
    
    static let availableApps: [SocialApp] = [
        SocialApp(
            name: "instagram", 
            displayName: "Instagram", 
            iconName: "camera.circle.fill",
            bundleIdentifier: "com.burbn.instagram",
            color: "pink"
        ),
        SocialApp(
            name: "snapchat", 
            displayName: "Snapchat", 
            iconName: "camera.aperture",
            bundleIdentifier: "com.toyopagroup.picaboo",
            color: "yellow"
        ),
        SocialApp(
            name: "x", 
            displayName: "X (Twitter)", 
            iconName: "at.circle.fill",
            bundleIdentifier: "com.atebits.Tweetie2",
            color: "black"
        ),
        SocialApp(
            name: "youtube", 
            displayName: "YouTube", 
            iconName: "play.rectangle.fill",
            bundleIdentifier: "com.google.ios.youtube",
            color: "red"
        ),
        SocialApp(
            name: "tiktok", 
            displayName: "TikTok", 
            iconName: "music.note.tv.fill",
            bundleIdentifier: "com.zhiliaoapp.musically",
            color: "black"
        )
    ]
}

// MARK: - Updated Stake Model with Real-time Properties
struct Stake: Identifiable, Codable {
    let id = UUID()
    let selectedApps: [SocialApp]
    let dailyTimeLimit: TimeInterval // in seconds
    let stakeAmount: Double // in dollars
    let startDate: Date
    let endDate: Date
    var isActive: Bool
    var currentUsage: TimeInterval
    var status: StakeStatus
    var lastUpdated: Date // NEW: Track when usage was last updated
    
    enum StakeStatus: String, Codable, CaseIterable {
        case active = "active"
        case completed = "completed"
        case failed = "failed"
        case paused = "paused"
    }
    
    // MARK: - Real-time Computed Properties
    var remainingTime: TimeInterval {
        return max(0, dailyTimeLimit - currentUsage)
    }
    
    var isOverLimit: Bool {
        return currentUsage > dailyTimeLimit
    }
    
    // FIXED: Calculate actual days remaining
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        
        // If stake has ended, return 0
        if now >= endDate {
            return 0
        }
        
        // Calculate days between now and end date
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(0, components.day ?? 0)
    }
    
    // NEW: Calculate hours remaining today
    var hoursRemainingToday: Double {
        return remainingTime / 3600.0 // Convert seconds to hours
    }
    
    // FIXED: Calculate actual progress (0.0 to 1.0)
    var dailyProgress: Double {
        guard dailyTimeLimit > 0 else { return 0 }
        return min(1.0, currentUsage / dailyTimeLimit)
    }
    
    // NEW: Calculate overall stake progress (days elapsed)
    var overallProgress: Double {
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let elapsedDays = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        guard totalDays > 0 else { return 0 }
        return min(1.0, Double(elapsedDays) / Double(totalDays))
    }
    
    // NEW: Check if stake should be auto-completed
    var shouldComplete: Bool {
        return Date() >= endDate && status == .active
    }
    
    // NEW: Check if it's a new day (reset daily usage)
    func isNewDay(since lastUpdate: Date) -> Bool {
        let calendar = Calendar.current
        return !calendar.isDate(lastUpdate, inSameDayAs: Date())
    }
    
    // NEW: Format time remaining nicely
    var formattedTimeRemaining: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m left today"
        } else if minutes > 0 {
            return "\(minutes)m left today"
        } else if remainingTime > 0 {
            return "< 1m left today"
        } else {
            return "Limit exceeded"
        }
    }
    
    // NEW: Format total stake duration
    var formattedStakeDuration: String {
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return "\(totalDays) day\(totalDays == 1 ? "" : "s")"
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var hasCompletedOnboarding: Bool = false
    var notificationsEnabled: Bool = true
    var preferredCurrency: String = "USD"
    var defaultStakeAmount: Double = 5.0
    var preferredStakeDuration: Int = 7 // days
    
    static let shared = UserPreferences()
}

// MARK: - Usage Data
struct AppUsageData: Identifiable, Codable {
    let id = UUID()
    let appBundleId: String
    let date: Date
    let totalTimeSpent: TimeInterval
    let pickupCount: Int
    let screenTimeLimit: TimeInterval?
}