//
//  StakesDashboardView.swift - COMPLETE UPDATED VERSION
//  screenstakeios
//

import SwiftUI

struct StakesDashboardView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @StateObject private var trackingService = StakeTrackingService.shared
    @State private var showingNewStake = false
    @State private var refreshing = false
    @State private var currentTime = Date()
    
    // Auto-refresh timer
    @State private var refreshTimer: Timer?
    
    // Brand colors
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    private let peach = Color(hex: "f4bda4")
    
    var activeStakes: [Stake] {
        persistenceManager.currentStakes.filter { $0.isActive && $0.status == .active }
    }
    
    var pastStakes: [Stake] {
        persistenceManager.currentStakes.filter { !$0.isActive || $0.status != .active }
            .sorted { $0.startDate > $1.startDate }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                blackBg.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header with real-time status
                        headerSection
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Active Stakes Section (real-time)
                        activeStakesSection
                        
                        // Past Stakes Section
                        pastStakesSection
                        
                        // Testing Controls
                        testingControlsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .refreshable {
                    await refreshData()
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingNewStake = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [orange, coral],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: orange.opacity(0.4), radius: 15, x: 0, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingNewStake) {
            AppSelectionView()
        }
        .onAppear {
            persistenceManager.loadStakes()
            startRealTimeUpdates()
        }
        .onDisappear {
            stopRealTimeUpdates()
        }
        .environmentObject(trackingService)
    }
    
    // MARK: - Real-time Updates
    private func startRealTimeUpdates() {
        print("🔄 Starting real-time dashboard updates")
        
        // Refresh every 30 seconds for live progress
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            currentTime = Date()
            persistenceManager.loadStakes() // Reload to get latest tracking updates
        }
    }
    
    private func stopRealTimeUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Header Section with Status
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screenstake")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(lightGray)
                    
                    HStack(spacing: 8) {
                        Text("Your digital accountability")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.7))
                        
                        // Real-time tracking indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(trackingService.isTrackingActive ? .green : .red)
                                .frame(width: 8, height: 8)
                            
                            Text(trackingService.isTrackingActive ? "Live" : "Offline")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(trackingService.isTrackingActive ? .green : .red)
                        }
                    }
                }
                
                Spacer()
                
                // Refresh button
                Button(action: {
                    Task { await refreshData() }
                }) {
                    Image(systemName: refreshing ? "arrow.clockwise" : "arrow.clockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(coral)
                        .rotationEffect(.degrees(refreshing ? 360 : 0))
                        .animation(refreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: refreshing)
                }
            }
            
            // Current time for reference
            Text("Updated: \(currentTime.formatted(date: .omitted, time: .shortened))")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(lightGray.opacity(0.5))
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Active Stakes",
                    value: "\(activeStakes.count)",
                    icon: "target",
                    color: coral
                )
                
                StatCard(
                    title: "Total Saved",
                    value: "$\(totalMoneyNotLost)",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "This Week",
                    value: "\(stakesThisWeek) stakes",
                    icon: "calendar.badge.clock",
                    color: peach
                )
                
                StatCard(
                    title: "Success Rate",
                    value: "\(successRate)%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: orange
                )
            }
        }
    }
    
    // MARK: - Active Stakes Section with Real-time Data
    private var activeStakesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Active Stakes",
                subtitle: "\(activeStakes.count) running • Live tracking",
                icon: "play.circle.fill"
            )
            
            if activeStakes.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Active Stakes",
                    subtitle: "Create your first stake to get started",
                    buttonText: "Create Stake",
                    action: {
                        showingNewStake = true
                    }
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(activeStakes) { stake in
                        ActiveStakeCard(stake: stake)
                            .environmentObject(trackingService)
                    }
                }
            }
        }
    }
    
    // MARK: - Past Stakes Section
    private var pastStakesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Past Stakes",
                subtitle: "\(pastStakes.count) completed",
                icon: "clock.arrow.circlepath"
            )
            
            if pastStakes.isEmpty {
                Text("No past stakes yet")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(lightGray.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(pastStakes.prefix(5)) { stake in
                        PastStakeRow(stake: stake)
                    }
                    
                    if pastStakes.count > 5 {
                        Button("View All Past Stakes") {
                            // TODO: Navigate to full history
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(coral)
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
    // MARK: - Corrected Testing Controls
    private var testingControlsSection: some View {
    VStack(spacing: 16) {
        SectionHeader(
            title: "Testing Controls",
            subtitle: RealScreenTimeManager.shared.getTrackingStatus(),
            icon: "testtube.2"
        )
        
        VStack(spacing: 16) {
            // Real Screen Time Status
            VStack(spacing: 8) {
                HStack {
                    Text("Screen Time Status")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(lightGray)
                    
                    Spacer()
                    
                    Button("Request Access") {
                        Task {
                            try? await RealScreenTimeManager.shared.requestScreenTimeAccess()
                        }
                    }
                    .buttonStyle(TestButtonStyle())
                    .disabled(RealScreenTimeManager.shared.isAuthorized)
                }
                
                Text(RealScreenTimeManager.shared.getTrackingStatus())
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(RealScreenTimeManager.shared.isAuthorized ? .green : .orange)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Current Usage Display
            VStack(spacing: 8) {
                Text("Current Usage Today")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(lightGray)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(SocialApp.availableApps, id: \.id) { app in
                        HStack(spacing: 6) {
                            Image(systemName: app.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(coral)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.displayName)
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                                    .foregroundColor(lightGray)
                                    .lineLimit(1)
                                
                                Text(formatTime(trackingService.getUsageForApp(app.bundleIdentifier)))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(coral)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundColor(Color.white.opacity(0.03))
                        )
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // CORRECTED: Stake-Focused Simulation
            VStack(spacing: 12) {
                Text("🎯 Simulate Usage for Active Stakes")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(lightGray)
                
                Text("Adds time only to apps in your active stakes")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(lightGray.opacity(0.7))
                
                HStack(spacing: 8) {
                    Button("15min") {
                        trackingService.simulateUsageForActiveStakes(totalMinutes: 15)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("30min") {
                        trackingService.simulateUsageForActiveStakes(totalMinutes: 30)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("1hr") {
                        trackingService.simulateUsageForActiveStakes(totalMinutes: 60)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("2hr") {
                        trackingService.simulateUsageForActiveStakes(totalMinutes: 120)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                }
            }
            
            // CORRECTED: Global Time Simulation  
            VStack(spacing: 12) {
                Text("⏰ Simulate Time Passage (All Apps)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(lightGray)
                
                Text("Simulates realistic usage across all apps over time")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(lightGray.opacity(0.7))
                
                HStack(spacing: 8) {
                    Button("1hr") {
                        trackingService.simulateTimePassage(hours: 1)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("2hr") {
                        trackingService.simulateTimePassage(hours: 2)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("4hr") {
                        trackingService.simulateTimePassage(hours: 4)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("8hr") {
                        trackingService.simulateTimePassage(hours: 8)
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Individual App Controls
            VStack(spacing: 12) {
                Text("📱 Set Exact App Usage")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(lightGray)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(SocialApp.availableApps.prefix(4), id: \.id) { app in
                        Menu {
                            Button("Set to 15 min") {
                                trackingService.setUsageForTesting(app: app, minutes: 15)
                                hapticFeedback(.light)
                            }
                            Button("Set to 30 min") {
                                trackingService.setUsageForTesting(app: app, minutes: 30)
                                hapticFeedback(.light)
                            }
                            Button("Set to 45 min") {
                                trackingService.setUsageForTesting(app: app, minutes: 45)
                                hapticFeedback(.light)
                            }
                            Button("Set to 1 hour") {
                                trackingService.setUsageForTesting(app: app, minutes: 60)
                                hapticFeedback(.light)
                            }
                            Button("Set to 2 hours") {
                                trackingService.setUsageForTesting(app: app, minutes: 120)
                                hapticFeedback(.light)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: app.iconName)
                                    .font(.system(size: 14))
                                    .foregroundColor(coral)
                                
                                Text(app.displayName)
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundColor(lightGray)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(lightGray.opacity(0.6))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(coral.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Management Controls
            VStack(spacing: 12) {
                Text("🔄 Management")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(lightGray)
                
                HStack(spacing: 12) {
                    Button("🌅 Reset Day") {
                        trackingService.resetUsageForTesting()
                        hapticFeedback(.success)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("🎯 Test Stake") {
                        addTestStakeWithLowLimit()
                        hapticFeedback(.success)
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("🔄 Refresh") {
                        Task {
                            await refreshData()
                            await RealScreenTimeManager.shared.forceRefreshUsage()
                        }
                        hapticFeedback(.light)
                    }
                    .buttonStyle(TestButtonStyle())
                }
                
                HStack(spacing: 12) {
                    Button("🗑️ Clear Stakes") {
                        persistenceManager.clearCache()
                        hapticFeedback(.warning)
                    }
                    .buttonStyle(TestButtonStyle(isDestructive: true))
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RealScreenTimeManager.shared.isAuthorized ? Color.green.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
    

// MARK: - Helper Methods (add these to StakesDashboardView)
private func addTestStakeWithLowLimit() {
    // Create stakes with very low limits for easy testing
    let testApps = Array(SocialApp.availableApps.prefix(Int.random(in: 1...2)))
    let amounts = [5.0, 10.0]
    let durations = [1, 3]
    let limits = [15.0, 30.0, 45.0] // Very low limits in minutes
    
    let selectedLimit = limits.randomElement()!
    let _ = persistenceManager.createStake(
        selectedApps: testApps,
        dailyTimeLimit: selectedLimit * 60, // convert to seconds
        stakeAmount: amounts.randomElement()!,
        duration: durations.randomElement()!
    )
    
    let apps = testApps.map { $0.displayName }.joined(separator: ", ")
    print("🎯 Created test stake: \(apps) - \(Int(selectedLimit)) min limit - $\(amounts.last!))")
}


func simulateUsageForActiveStakes(totalMinutes: Double) {
    let totalSeconds = totalMinutes * 60
    print("🎯 Simulating \(totalMinutes) minutes for active stakes...")
    
    let activeStakes = persistenceManager.getActiveStakes()
    guard !activeStakes.isEmpty else {
        print("⚠️ No active stakes found")
        return
    }
    
    // Get all unique apps from active stakes
    let allStakeApps = Set(activeStakes.flatMap { $0.selectedApps })
    let usagePerApp = totalSeconds / Double(allStakeApps.count)
    
    print("📊 Adding \(formatTime(usagePerApp)) to each of \(allStakeApps.count) tracked apps")
    
    for app in allStakeApps {
        let currentUsage = currentDayUsage[app.bundleIdentifier] ?? 0
        let newUsage = currentUsage + usagePerApp
        currentDayUsage[app.bundleIdentifier] = newUsage
        baseUsageData[app.bundleIdentifier] = newUsage
        
        print("   \(app.displayName): \(formatTime(currentUsage)) → \(formatTime(newUsage))")
    }
    
    saveUsageData()
    
    Task {
        await updateUsageAndCheckStakes()
    }
    
    print("✅ Added \(formatTime(totalSeconds)) total across \(allStakeApps.count) apps")
}

func setUsageForTesting(app: SocialApp, minutes: Double) {
    let seconds = minutes * 60
    currentDayUsage[app.bundleIdentifier] = seconds
    baseUsageData[app.bundleIdentifier] = seconds
    saveUsageData()
    
    Task {
        await updateUsageAndCheckStakes()
    }
    
    print("🧪 Set \(app.displayName) to exactly \(formatTime(seconds))")
}

private func hapticFeedback(_ style: UINotificationFeedbackGenerator.FeedbackType) {
    let feedback = UINotificationFeedbackGenerator()
    feedback.notificationOccurred(style)
}

private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let feedback = UIImpactFeedbackGenerator(style: style)
    feedback.impactOccurred()
}

private func formatTime(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}
    
    // MARK: - Computed Properties
    private var totalMoneyNotLost: Int {
        pastStakes.filter { $0.status == .completed }.reduce(0) { $0 + Int($1.stakeAmount) }
    }
    
    private var stakesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return persistenceManager.currentStakes.filter { $0.startDate >= weekAgo }.count
    }
    
    private var successRate: Int {
        guard !pastStakes.isEmpty else { return 0 }
        let successful = pastStakes.filter { $0.status == .completed }.count
        return Int((Double(successful) / Double(pastStakes.count)) * 100)
    }
    
    // MARK: - Actions
    @MainActor
    private func refreshData() async {
        refreshing = true
        
        // Simulate network delay
        try? await Task.sleep(for: .seconds(1))
        
        // Reload from disk to test persistence
        persistenceManager.loadStakes()
        currentTime = Date()
        
        refreshing = false
    }
    
    private func addTestStake() {
        let testApps = Array(SocialApp.availableApps.prefix(Int.random(in: 1...3)))
        let amounts = [5.0, 10.0, 20.0, 50.0]
        let durations = [1, 3, 7, 14]
        let limits = [30.0, 60.0, 120.0, 180.0] // minutes
        
        let _ = persistenceManager.createStake(
            selectedApps: testApps,
            dailyTimeLimit: limits.randomElement()! * 60, // convert to seconds
            stakeAmount: amounts.randomElement()!,
            duration: durations.randomElement()!
        )
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    private let lightGray = Color(hex: "f6f6f6")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(lightGray)
            
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(lightGray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(coral)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(lightGray)
                
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(lightGray.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

struct ActiveStakeCard: View {
    let stake: Stake
    @EnvironmentObject var trackingService: StakeTrackingService
    
    // Auto-refresh every 30 seconds
    @State private var refreshTimer: Timer?
    @State private var currentTime = Date()
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    // Real-time calculations
    private var currentUsage: TimeInterval {
        trackingService.getTotalUsageForStake(stake)
    }
    
    private var dailyProgress: Double {
        guard stake.dailyTimeLimit > 0 else { return 0 }
        return min(1.0, currentUsage / stake.dailyTimeLimit)
    }
    
    private var progressColor: Color {
        switch dailyProgress {
        case 1.0...: return .red
        case 0.9..<1.0: return .orange
        case 0.7..<0.9: return .yellow
        default: return coral
        }
    }
    
    private var urgencyLevel: UrgencyLevel {
        switch dailyProgress {
        case 1.0...: return .critical
        case 0.9..<1.0: return .high
        case 0.7..<0.9: return .medium
        default: return .low
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with urgency indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("$\(Int(stake.stakeAmount)) at risk")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundColor(coral)
                        
                        urgencyIndicator
                    }
                    
                    Text(stake.selectedApps.map { $0.displayName }.joined(separator: ", "))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(daysRemainingText)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(lightGray)
                    
                    Text("Updated: \(trackingService.lastUpdateTime.formatted(date: .omitted, time: .shortened))")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.5))
                }
            }
            
            // Usage information with real-time updates
            VStack(spacing: 12) {
                HStack {
                    Text("Today's Usage:")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(lightGray)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(formatTime(currentUsage)) / \(formatTime(stake.dailyTimeLimit))")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(progressColor)
                        
                        if dailyProgress > 1.0 {
                            Text("EXCEEDED by \(formatTime(currentUsage - stake.dailyTimeLimit))")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Enhanced progress bar with animation
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        // Progress fill
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * min(1.0, dailyProgress), height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.5), value: dailyProgress)
                        
                        // Over-limit indicator
                        if dailyProgress > 1.0 {
                            Rectangle()
                                .fill(Color.red.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)
                                .overlay(
                                    HStack(spacing: 4) {
                                        ForEach(0..<3, id: \.self) { _ in
                                            Rectangle()
                                                .fill(Color.red)
                                                .frame(width: 2, height: 8)
                                        }
                                    }
                                )
                        }
                    }
                }
                .frame(height: 8)
                
                // Status and time remaining
                HStack {
                    statusMessage
                    
                    Spacer()
                    
                    Text("\(Int(dailyProgress * 100))%")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundColor(progressColor)
                }
            }
            
            // Overall stake progress (time-based)
            if calculateRealDaysRemaining() > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Stake Progress:")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(Int(stake.overallProgress * 100))% complete")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(lightGray.opacity(0.7))
                    }
                    
                    ProgressView(value: stake.overallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: coral.opacity(0.6)))
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(2)
                        .scaleEffect(y: 0.5)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .onAppear(perform: startRefreshTimer)
        .onDisappear(perform: stopRefreshTimer)
    }
    
    // MARK: - View Components
    private var urgencyIndicator: some View {
        Group {
            switch urgencyLevel {
            case .critical:
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("EXCEEDED")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundColor(.red)
                }
            case .high:
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundColor(.orange)
                    Text("URGENT")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundColor(.orange)
                }
            case .medium:
                Image(systemName: "clock.fill")
                    .foregroundColor(.yellow)
            case .low:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            }
        }
        .font(.system(size: 14))
    }
    
    private var statusMessage: some View {
        Group {
            if dailyProgress > 1.0 {
                Text("⚠️ LIMIT EXCEEDED")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundColor(.red)
            } else if dailyProgress > 0.9 {
                Text("🚨 \(formatTime(stake.dailyTimeLimit - currentUsage)) remaining")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.orange)
            } else {
                Text("\(formatTime(stake.dailyTimeLimit - currentUsage)) remaining")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(lightGray.opacity(0.7))
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .foregroundColor(Color.white.opacity(urgencyLevel == .critical ? 0.08 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(progressColor.opacity(urgencyLevel.rawValue > 2 ? 0.6 : 0.3), 
                           lineWidth: urgencyLevel.rawValue > 2 ? 2 : 1)
            )
    }
    
    // MARK: - Computed Properties
    private var daysRemainingText: String {
        let days = calculateRealDaysRemaining()
        switch days {
        case 0: return "Last day!"
        case 1: return "1 day left"
        default: return "\(days) days left"
        }
    }
    
    // MARK: - Helper Methods
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func calculateRealDaysRemaining() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        if now >= stake.endDate {
            return 0
        }
        
        let components = calendar.dateComponents([.day], from: now, to: stake.endDate)
        return max(0, components.day ?? 0)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum UrgencyLevel: Int {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

struct PastStakeRow: View {
    let stake: Stake
    
    private let lightGray = Color(hex: "f6f6f6")
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("$\(Int(stake.stakeAmount)) • \(stake.selectedApps.map { $0.displayName }.joined(separator: ", "))")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(lightGray)
                    .lineLimit(1)
                
                Text(stake.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(lightGray.opacity(0.6))
            }
            
            Spacer()
            
            Text(stake.status.rawValue.capitalized)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .foregroundColor(statusColor.opacity(0.2))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color.white.opacity(0.03))
        )
    }
    
    private var statusIcon: String {
        switch stake.status {
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .paused:
            return "pause.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch stake.status {
        case .completed:
            return .green
        case .failed:
            return .red
        case .paused:
            return .yellow
        default:
            return Color(hex: "f38453")
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonText: String
    let action: () -> Void
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(coral.opacity(0.6))
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(lightGray)
                
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(lightGray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text(buttonText)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [coral, coral.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 40)
    }
}

struct TestButtonStyle: ButtonStyle {
    var isDestructive = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(isDestructive ? .red.opacity(0.8) : Color(hex: "f38453"))
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}

