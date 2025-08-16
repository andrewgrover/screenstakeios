//
//  StakeSetupView.swift
//  screenstakeios
//
//  View for setting up stake amount, time limit, and duration
//

import SwiftUI

struct StakeSetupView: View {
    let selectedApps: [SocialApp]
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var persistenceManager = PersistenceManager.shared
    
    @State private var stakeAmount: Double = 5.0
    @State private var customStakeAmount: String = ""
    @State private var showingCustomAmount = false
    @State private var dailyTimeLimit: Double = 60 // minutes
    @State private var stakeDuration: Int = 7 // days
    @State private var showingPaymentSetup = false
    @State private var isCreatingStake = false
    
    // Animation states
    @State private var contentOpacity: Double = 0
    @State private var cardOffset: CGFloat = 30
    
    // Brand colors
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let peach = Color(hex: "f4bda4")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    // Stake amount options
    private let stakeAmounts: [Double] = [1, 5, 10, 20, 50]
    
    // Time limit options (in minutes) - converted to hours for display
    private let timeLimits: [Double] = [30, 60, 120, 180, 300] // 0.5hr, 1hr, 2hr, 3hr, 5hr
    
    // Duration options (in days)
    private let durations: [Int] = [1, 3, 7, 14, 30]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                blackBg
                    .ignoresSafeArea()
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        blackBg,
                        orange.opacity(0.05),
                        blackBg
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .blendMode(.screen)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Set Your Stake")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(lightGray)
                            
                            Text("Configure your stake amount, daily time limit, and duration")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .opacity(contentOpacity)
                        
                        // Selected Apps Summary
                        VStack(spacing: 12) {
                            Text("Apps in This Stake")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(coral)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(selectedApps, id: \.id) { app in
                                    VStack(spacing: 6) {
                                        Image(systemName: app.iconName)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(coral)
                                        
                                        Text(app.displayName)
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundColor(lightGray)
                                            .lineLimit(1)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                            .stroke(coral.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .offset(y: cardOffset)
                        .opacity(contentOpacity)
                        
                        // Stake Amount Section
                        SettingSection(
                            title: "Stake Amount",
                            subtitle: "How much are you willing to risk?",
                            content: {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("$\(formattedStakeAmount)")
                                            .font(.system(.title, design: .rounded, weight: .bold))
                                            .foregroundColor(coral)
                                        Spacer()
                                    }
                                    
                                    // Preset amounts - Two rows
                                    VStack(spacing: 12) {
                                        // First row: $1, $5, $10, $20
                                        HStack(spacing: 8) {
                                            ForEach(Array(stakeAmounts.prefix(4)), id: \.self) { amount in
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        stakeAmount = amount
                                                        showingCustomAmount = false
                                                        customStakeAmount = ""
                                                    }
                                                }) {
                                                    Text("$\(formatAmount(amount))")
                                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                        .foregroundColor(stakeAmount == amount && !showingCustomAmount ? .white : lightGray)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            Capsule()
                                                                .fill(stakeAmount == amount && !showingCustomAmount ? coral : Color.white.opacity(0.1))
                                                        )
                                                }
                                            }
                                        }
                                        
                                        // Second row: $50 and Custom
                                        HStack(spacing: 8) {
                                            // $50 button
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    stakeAmount = 50
                                                    showingCustomAmount = false
                                                    customStakeAmount = ""
                                                }
                                            }) {
                                                Text("$50")
                                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                    .foregroundColor(stakeAmount == 50 && !showingCustomAmount ? .white : lightGray)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(stakeAmount == 50 && !showingCustomAmount ? coral : Color.white.opacity(0.1))
                                                    )
                                            }
                                            
                                            // Custom amount button
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    showingCustomAmount = true
                                                    customStakeAmount = stakeAmount > 50 ? String(Int(stakeAmount)) : ""
                                                }
                                            }) {
                                                Text("Custom")
                                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                    .foregroundColor(showingCustomAmount ? .white : lightGray)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(showingCustomAmount ? coral : Color.white.opacity(0.1))
                                                    )
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    // Custom amount input
                                    if showingCustomAmount {
                                        VStack(spacing: 8) {
                                            TextField("Enter amount", text: $customStakeAmount)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .keyboardType(.numberPad)
                                                .onChange(of: customStakeAmount) { _, newValue in
                                                    // Limit to numbers only and max $500
                                                    let filtered = newValue.filter { $0.isNumber }
                                                    if let amount = Double(filtered), amount <= 500 {
                                                        customStakeAmount = filtered
                                                        stakeAmount = amount
                                                    } else if filtered.isEmpty {
                                                        customStakeAmount = ""
                                                        stakeAmount = 0
                                                    } else {
                                                        customStakeAmount = "500"
                                                        stakeAmount = 500
                                                    }
                                                }
                                                .font(.system(.body, design: .rounded))
                                            
                                            Text("Maximum: $500")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(lightGray.opacity(0.6))
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                        )
                        .offset(y: cardOffset)
                        .opacity(contentOpacity)
                        
                        // Time Limit Section
                        SettingSection(
                            title: "Daily Time Limit",
                            subtitle: "Maximum time per day across all selected apps",
                            content: {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text(formatTimeLimit(dailyTimeLimit))
                                            .font(.system(.title, design: .rounded, weight: .bold))
                                            .foregroundColor(coral)
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 8) {
                                        ForEach(timeLimits, id: \.self) { limit in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    dailyTimeLimit = limit
                                                }
                                            }) {
                                                Text(formatTimeLimitButton(limit))
                                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                    .foregroundColor(dailyTimeLimit == limit ? .white : lightGray)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(dailyTimeLimit == limit ? coral : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        )
                        .offset(y: cardOffset)
                        .opacity(contentOpacity)
                        
                        // Duration Section
                        SettingSection(
                            title: "Stake Duration",
                            subtitle: "How long will this stake last?",
                            content: {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("\(stakeDuration) day\(stakeDuration == 1 ? "" : "s")")
                                            .font(.system(.title, design: .rounded, weight: .bold))
                                            .foregroundColor(coral)
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 12) {
                                        ForEach(durations, id: \.self) { duration in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    stakeDuration = duration
                                                }
                                            }) {
                                                Text("\(duration)d")
                                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                    .foregroundColor(stakeDuration == duration ? .white : lightGray)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(stakeDuration == duration ? coral : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        )
                        .offset(y: cardOffset)
                        .opacity(contentOpacity)
                        
                        // Summary Card
                        VStack(spacing: 16) {
                            Text("Stake Summary")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(lightGray)
                            
                            VStack(spacing: 12) {
                                SummaryRow(
                                    icon: "dollarsign.circle.fill",
                                    title: "Risk Amount",
                                    value: "$\(formattedStakeAmount)"
                                )
                                
                                SummaryRow(
                                    icon: "clock.fill",
                                    title: "Daily Limit",
                                    value: formatTimeLimit(dailyTimeLimit)
                                )
                                
                                SummaryRow(
                                    icon: "calendar.badge.clock",
                                    title: "Duration",
                                    value: "\(stakeDuration) day\(stakeDuration == 1 ? "" : "s")"
                                )
                                
                                SummaryRow(
                                    icon: "apps.iphone",
                                    title: "Apps",
                                    value: "\(selectedApps.count) selected"
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .stroke(coral.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .offset(y: cardOffset)
                        .opacity(contentOpacity)
                        
                        Spacer(minLength: 120)
                    }
                }
                .scrollIndicators(.hidden)
                
                // Bottom Action Section
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Create Stake Button
                        Button(action: {
                            // Navigate to payment setup instead of creating stake directly
                            showingPaymentSetup = true
                        }) {
                            ZStack {
                                LinearGradient(
                                    colors: [orange, coral],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                
                                HStack(spacing: 8) {
                                    Text("Continue to Payment")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .cornerRadius(28)
                            .shadow(color: orange.opacity(0.3), radius: 20, x: 0, y: 10)
                        }
                        .padding(.horizontal, 24)
                        
                        // Back Button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back to App Selection")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(peach.opacity(0.8))
                            .padding(.vertical, 12)
                        }
                        .disabled(isCreatingStake)
                    }
                    .padding(.bottom, 34)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            // Load user's preferred defaults
            stakeAmount = persistenceManager.userPreferences.defaultStakeAmount
            
            // Animate content in
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                contentOpacity = 1
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                cardOffset = 0
            }
        }
        .fullScreenCover(isPresented: $showingPaymentSetup) {
            PaymentSetupView(
                selectedApps: selectedApps,
                stakeAmount: stakeAmount,
                dailyTimeLimit: dailyTimeLimit,
                stakeDuration: stakeDuration
            )
        }
    }
    
    // MARK: - Actions
    private func resetForm() {
        stakeAmount = persistenceManager.userPreferences.defaultStakeAmount
        dailyTimeLimit = 60
        stakeDuration = 7
        showingCustomAmount = false
        customStakeAmount = ""
    }
    
    // MARK: - Helper Functions
    private var formattedStakeAmount: String {
        if stakeAmount == floor(stakeAmount) {
            return String(Int(stakeAmount))
        } else {
            return String(format: "%.2f", stakeAmount)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return String(Int(amount))
    }
    
    private func formatTimeLimit(_ minutes: Double) -> String {
        if minutes < 60 {
            return "\(Int(minutes)) min"
        } else {
            let hours = minutes / 60
            if hours == floor(hours) {
                return "\(Int(hours)) hr"
            } else {
                return String(format: "%.1f hr", hours)
            }
        }
    }
    
    private func formatTimeLimitButton(_ minutes: Double) -> String {
        if minutes < 60 {
            return "30m"
        } else {
            let hours = Int(minutes / 60)
            return "\(hours)hr"
        }
    }
}

// MARK: - Setting Section Component
struct SettingSection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(lightGray)
                    Spacer()
                }
                
                HStack {
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.7))
                    Spacer()
                }
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Summary Row Component
struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(coral)
                .frame(width: 20)
            
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(lightGray.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(lightGray)
        }
    }
}

// MARK: - Preview
#Preview {
    StakeSetupView(selectedApps: Array(SocialApp.availableApps.prefix(2)))
}