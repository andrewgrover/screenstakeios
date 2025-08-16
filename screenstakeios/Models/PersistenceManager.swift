//
//  PersistenceManager.swift
//  screenstakeios
//
//  Handles all data persistence using UserDefaults and FileManager
//  Future-ready for Core Data migration
//

import Foundation

@MainActor
class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    // MARK: - File URLs
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var stakesFileURL: URL {
        documentsDirectory.appendingPathComponent("stakes.json")
    }
    
    private var usageDataFileURL: URL {
        documentsDirectory.appendingPathComponent("usage_data.json")
    }
    
    // MARK: - Published Properties
    @Published var currentStakes: [Stake] = []
    @Published var userPreferences: UserPreferences = UserPreferences.shared
    @Published var usageHistory: [AppUsageData] = []
    
    private init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    private func loadAllData() {
        loadUserPreferences()
        loadStakes()
        loadUsageData()
    }
    
    // MARK: - User Preferences
    func loadUserPreferences() {
        if let data = userDefaults.data(forKey: "user_preferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = preferences
        }
    }
    
    func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            userDefaults.set(data, forKey: "user_preferences")
        }
    }
    
    func updateOnboardingStatus(_ completed: Bool) {
        userPreferences.hasCompletedOnboarding = completed
        saveUserPreferences()
    }
    
    // MARK: - Stakes Management
    func loadStakes() {
        do {
            let data = try Data(contentsOf: stakesFileURL)
            currentStakes = try JSONDecoder().decode([Stake].self, from: data)
        } catch {
            print("Failed to load stakes: \(error)")
            currentStakes = []
        }
    }
    
    func saveStakes() {
        do {
            let data = try JSONEncoder().encode(currentStakes)
            try data.write(to: stakesFileURL)
        } catch {
            print("Failed to save stakes: \(error)")
        }
    }
    
    func createStake(
        selectedApps: [SocialApp],
        dailyTimeLimit: TimeInterval,
        stakeAmount: Double,
        duration: Int
    ) -> Stake {
        let endDate = Calendar.current.date(byAdding: .day, value: duration, to: Date()) ?? Date()
        
        let newStake = Stake(
            selectedApps: selectedApps,
            dailyTimeLimit: dailyTimeLimit,
            stakeAmount: stakeAmount,
            startDate: Date(),
            endDate: endDate,
            isActive: true,
            currentUsage: 0,
            status: .active
        )
        
        currentStakes.append(newStake)
        saveStakes()
        
        return newStake
    }
    
    func updateStake(_ stake: Stake) {
        if let index = currentStakes.firstIndex(where: { $0.id == stake.id }) {
            currentStakes[index] = stake
            saveStakes()
        }
    }
    
    func getActiveStakes() -> [Stake] {
        return currentStakes.filter { $0.isActive && $0.status == .active }
    }
    
    // MARK: - Usage Data
    func loadUsageData() {
        do {
            let data = try Data(contentsOf: usageDataFileURL)
            usageHistory = try JSONDecoder().decode([AppUsageData].self, from: data)
        } catch {
            print("Failed to load usage data: \(error)")
            usageHistory = []
        }
    }
    
    func saveUsageData() {
        do {
            let data = try JSONEncoder().encode(usageHistory)
            try data.write(to: usageDataFileURL)
        } catch {
            print("Failed to save usage data: \(error)")
        }
    }
    
    func addUsageData(_ usage: AppUsageData) {
        usageHistory.append(usage)
        saveUsageData()
    }
    
    // MARK: - Data Migration & Cleanup
    func performDataMigration() {
        // Future method for migrating to Core Data when needed
        // For now, just ensure data integrity
        validateDataIntegrity()
    }
    
    private func validateDataIntegrity() {
        // Remove any corrupted or invalid stakes
        currentStakes = currentStakes.filter { stake in
            !stake.selectedApps.isEmpty && stake.stakeAmount > 0 && stake.dailyTimeLimit > 0
        }
        
        // Clean up old usage data (keep last 90 days)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        usageHistory = usageHistory.filter { $0.date >= cutoffDate }
        
        saveStakes()
        saveUsageData()
    }
    
    // MARK: - Cache Management
    func clearCache() {
        try? fileManager.removeItem(at: stakesFileURL)
        try? fileManager.removeItem(at: usageDataFileURL)
        userDefaults.removeObject(forKey: "user_preferences")
        
        currentStakes = []
        usageHistory = []
        userPreferences = UserPreferences.shared
    }
    
    // MARK: - Backup & Restore
    func exportUserData() -> Data? {
        struct ExportData: Codable {
            let stakes: [Stake]
            let preferences: UserPreferences
            let usage: [AppUsageData]
        }
        
        let exportData = ExportData(
            stakes: currentStakes,
            preferences: userPreferences,
            usage: usageHistory
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func importUserData(from data: Data) throws {
        struct ExportData: Codable {
            let stakes: [Stake]
            let preferences: UserPreferences
            let usage: [AppUsageData]
        }
        
        let importedData = try JSONDecoder().decode(ExportData.self, from: data)
        
        currentStakes = importedData.stakes
        userPreferences = importedData.preferences
        usageHistory = importedData.usage
        
        saveStakes()
        saveUserPreferences()
        saveUsageData()
    }
}