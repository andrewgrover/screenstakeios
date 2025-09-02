//
//  StakesDashboardView.swift
//  screenstakeios
//
//  Home screen showing active and past stakes for testing persistence
//

import SwiftUI

struct StakesDashboardView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @State private var showingNewStake = false
    @State private var refreshing = false
    
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
                        // Header
                        headerSection
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Active Stakes Section
                        activeStakesSection
                        
                        // Past Stakes Section
                        pastStakesSection
                        
                        // Debug Section (for testing)
                        debugSection
                        
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
            // Reload data when view appears to test persistence
            persistenceManager.loadStakes()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screenstake")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(lightGray)
                    
                    Text("Your digital accountability")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.7))
                }
                
                Spacer()
                
                // Refresh button for testing
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
    
    // MARK: - Active Stakes Section
    private var activeStakesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Active Stakes",
                subtitle: "\(activeStakes.count) running",
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
    
    // MARK: - Debug Section
    private var debugSection: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Debug Info",
                subtitle: "For testing persistence",
                icon: "ladybug.fill"
            )
            
            VStack(spacing: 8) {
                DebugRow(label: "Total Stakes in Memory", value: "\(persistenceManager.currentStakes.count)")
                DebugRow(label: "Active Stakes", value: "\(activeStakes.count)")
                DebugRow(label: "Completed Stakes", value: "\(pastStakes.filter { $0.status == .completed }.count)")
                DebugRow(label: "Failed Stakes", value: "\(pastStakes.filter { $0.status == .failed }.count)")
                
                HStack(spacing: 12) {
                    Button("Add Test Stake") {
                        addTestStake()
                    }
                    .buttonStyle(DebugButtonStyle())
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .buttonStyle(DebugButtonStyle(isDestructive: true))
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
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
        
        // Add haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    private func clearAllData() {
        persistenceManager.clearCache()
        
        // Add haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
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
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(Int(stake.stakeAmount)) at risk")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(coral)
                    
                    Text("\(stake.selectedApps.map { $0.displayName }.joined(separator: ", "))")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(stake.daysRemaining) days left")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(lightGray)
                    
                    Text("Daily limit: \(formatTimeLimit(stake.dailyTimeLimit))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.6))
                }
            }
            
            // Progress bar (mock data for now)
            ProgressView(value: 0.3)
                .progressViewStyle(LinearProgressViewStyle(tint: coral))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(coral.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func formatTimeLimit(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(Int(minutes))m"
        } else {
            return "\(Int(minutes / 60))h"
        }
    }
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

struct DebugRow: View {
    let label: String
    let value: String
    
    private let lightGray = Color(hex: "f6f6f6")
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(lightGray.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(lightGray)
        }
    }
}

struct DebugButtonStyle: ButtonStyle {
    var isDestructive = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .foregroundColor(isDestructive ? .red.opacity(0.8) : Color(hex: "f38453"))
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}

#Preview {
    StakesDashboardView()
        .environmentObject(PersistenceManager.shared)
}