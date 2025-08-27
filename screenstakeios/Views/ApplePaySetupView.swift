//
//  ApplePaySetupView.swift
//  screenstakeios
//
//  Apple Pay setup for stake payments - FIXED VERSION
//

import SwiftUI
import PassKit

struct ApplePaySetupView: View {
    let selectedApps: [SocialApp]
    let stakeAmount: Double
    let dailyTimeLimit: Double
    let stakeDuration: Int
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var persistenceManager = PersistenceManager.shared
    
    @State private var hasConsented = false
    @State private var understandsCharges = false
    @State private var acceptsTerms = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showConsentDetails = false
    
    // Brand colors
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let peach = Color(hex: "f4bda4")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    var body: some View {
        NavigationStack {
            ZStack {
                blackBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.and.123")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(coral)
                            
                            Text("Payment Authorization")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(lightGray)
                            
                            Text("Set up secure payment for your stake")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Development Notice
                        VStack(spacing: 12) {
                            Text("🧪 Development Mode")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(.yellow)
                            
                            Text("This will create a test stake without real payment processing")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        
                        // Stake Details & Consent
                        VStack(spacing: 20) {
                            // Clear Charge Explanation
                            VStack(alignment: .leading, spacing: 12) {
                                Label("How Charges Work", systemImage: "info.circle.fill")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundColor(coral)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ChargeExplanationRow(
                                        icon: "clock",
                                        text: "Daily limit: \(formatTimeLimit(dailyTimeLimit))",
                                        highlight: true
                                    )
                                    
                                    ChargeExplanationRow(
                                        icon: "dollarsign.circle",
                                        text: "Charge amount: $\(Int(stakeAmount))",
                                        highlight: true
                                    )
                                    
                                    ChargeExplanationRow(
                                        icon: "exclamationmark.triangle",
                                        text: "You're ONLY charged if you exceed the limit"
                                    )
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(Color.white.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(coral.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            
                            // Consent Checkboxes
                            VStack(spacing: 16) {
                                ConsentCheckbox(
                                    isChecked: $hasConsented,
                                    text: "I authorize a $\(Int(stakeAmount)) charge if I exceed my daily \(formatTimeLimit(dailyTimeLimit)) limit"
                                )
                                
                                ConsentCheckbox(
                                    isChecked: $understandsCharges,
                                    text: "I understand this is a test stake for development"
                                )
                                
                                ConsentCheckbox(
                                    isChecked: $acceptsTerms,
                                    text: "I accept the Terms of Service and Privacy Policy"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 120)
                    }
                }
                .scrollIndicators(.hidden)
                
                // Bottom Actions
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Test Stake Button (instead of Apple Pay for now)
                        Button(action: {
                            createTestStake()
                        }) {
                            ZStack {
                                LinearGradient(
                                    colors: allConsentsGiven ? [orange, coral] : [Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                
                                if isProcessing {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        Text("Creating Stake...")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                        Text("Create Test Stake")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .cornerRadius(28)
                            .shadow(
                                color: allConsentsGiven ? orange.opacity(0.3) : .clear,
                                radius: 20,
                                x: 0,
                                y: 10
                            )
                        }
                        .disabled(!allConsentsGiven || isProcessing)
                        .padding(.horizontal, 24)
                        
                        // Back Button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back to Stake Setup")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(peach.opacity(0.8))
                            .padding(.vertical, 12)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.bottom, 34)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .overlay(
            Group {
                if isProcessing {
                    ProcessingOverlay()
                }
            }
        )
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Test Stake Created!", isPresented: $showSuccess) {
            Button("Continue") {
                dismiss()
            }
        } message: {
            Text("Your test stake is now active! This is a development version - no real payments will be processed.")
        }
    }
    
    // MARK: - Computed Properties
    private var allConsentsGiven: Bool {
        return hasConsented && understandsCharges && acceptsTerms
    }
    
    // MARK: - Actions
    private func createTestStake() {
        guard allConsentsGiven else { return }
        
        isProcessing = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Create the test stake
            let timeInSeconds = dailyTimeLimit * 60
            let _ = persistenceManager.createStake(
                selectedApps: selectedApps,
                dailyTimeLimit: timeInSeconds,
                stakeAmount: stakeAmount,
                duration: stakeDuration
            )
            
            // Show success
            isProcessing = false
            showSuccess = true
            
            // Success feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
    }
    
    // MARK: - Helper Functions
    private func formatTimeLimit(_ minutes: Double) -> String {
        if minutes < 60 {
            return "\(Int(minutes)) minutes"
        } else {
            let hours = minutes / 60
            if hours == floor(hours) {
                return "\(Int(hours)) hour\(Int(hours) == 1 ? "" : "s")"
            } else {
                return String(format: "%.1f hours", hours)
            }
        }
    }
}

// MARK: - Supporting Views (keeping existing ones)
struct ConsentCheckbox: View {
    @Binding var isChecked: Bool
    let text: String
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isChecked.toggle()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isChecked ? coral : lightGray.opacity(0.5))
                
                Text(text)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(lightGray)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChargeExplanationRow: View {
    let icon: String
    let text: String
    var highlight: Bool = false
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(highlight ? coral : lightGray.opacity(0.6))
                .frame(width: 20)
            
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: highlight ? .semibold : .regular))
                .foregroundColor(highlight ? lightGray : lightGray.opacity(0.8))
            
            Spacer()
        }
    }
}

struct ProcessingOverlay: View {
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    
    var body: some View {
        ZStack {
            blackBg.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: lightGray))
                    .scaleEffect(1.5)
                
                Text("Creating your test stake...")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(lightGray)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(blackBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(lightGray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    ApplePaySetupView(
        selectedApps: Array(SocialApp.availableApps.prefix(2)),
        stakeAmount: 10,
        dailyTimeLimit: 120,
        stakeDuration: 7
    )
}