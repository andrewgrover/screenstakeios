//
//  DataModels.swift
//  screenstakeios
//
//  Core data models and persistence layer
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

// MARK: - Stake Model
struct Stake: Identifiable, Codable {
    let id = UUID()
    let selectedApps: [SocialApp]
    let dailyTimeLimit: TimeInterval // in seconds
    let stakeAmount: Double // in dollars
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let currentUsage: TimeInterval
    let status: StakeStatus
    
    enum StakeStatus: String, Codable, CaseIterable {
        case active = "active"
        case completed = "completed"
        case failed = "failed"
        case paused = "paused"
    }
    
    var remainingTime: TimeInterval {
        return dailyTimeLimit - currentUsage
    }
    
    var isOverLimit: Bool {
        return currentUsage > dailyTimeLimit
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
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