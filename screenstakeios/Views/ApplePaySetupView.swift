//
//  ApplePaySetupView.swift
//  screenstakeios
//
//  Apple Pay setup for stake payments with consent flow - ALL iOS 17.0 compatibility errors fixed
//

import SwiftUI
import PassKit

struct ApplePaySetupView: View {
    let selectedApps: [SocialApp]
    let stakeAmount: Double
    let dailyTimeLimit: Double
    let stakeDuration: Int
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentManager = StripePaymentManager.shared
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
                        
                        // Apple Pay Benefits
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Secure & Private")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundColor(lightGray)
                                    
                                    Text("Your card details are never shared with us")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(lightGray.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bank-Level Encryption")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundColor(lightGray)
                                    
                                    Text("Powered by Apple Pay & Stripe")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(lightGray.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundColor(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                                    
                                    ChargeExplanationRow(
                                        icon: "arrow.uturn.backward",
                                        text: "24-hour cancellation window for disputes"
                                    )
                                    
                                    ChargeExplanationRow(
                                        icon: "shield",
                                        text: "Daily charge cap: $\(Int(stakeAmount)) maximum"
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
                                    text: "I authorize Screenstake to charge $\(Int(stakeAmount)) to my payment method if I exceed my daily \(formatTimeLimit(dailyTimeLimit)) screen time limit"
                                )
                                
                                ConsentCheckbox(
                                    isChecked: $understandsCharges,
                                    text: "I understand charges are automatic and occur only when limits are exceeded"
                                )
                                
                                ConsentCheckbox(
                                    isChecked: $acceptsTerms,
                                    text: "I accept the Terms of Service and Privacy Policy"
                                )
                            }
                            
                            // Learn More Button
                            Button(action: {
                                showConsentDetails = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("View detailed terms")
                                        .font(.system(.caption, design: .rounded))
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(coral.opacity(0.8))
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
                        // Apple Pay Button
                        if PKPaymentAuthorizationController.canMakePayments() {
                            Button(action: {
                                setupApplePay()
                            }) {
                                ZStack {
                                    if allConsentsGiven {
                                        // Apple Pay branded button
                                        ApplePayButton()
                                            .frame(height: 56)
                                    } else {
                                        // Disabled state
                                        RoundedRectangle(cornerRadius: 28)
                                            .foregroundColor(Color.gray.opacity(0.3))
                                            .frame(height: 56)
                                            .overlay(
                                                HStack(spacing: 8) {
                                                    Image(systemName: "lock.fill")
                                                    Text("Complete Consent Above")
                                                }
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            )
                                    }
                                }
                            }
                            .disabled(!allConsentsGiven || isProcessing)
                            .padding(.horizontal, 24)
                        } else {
                            // Fallback for devices without Apple Pay
                            Button(action: {
                                // Show alternative payment method
                            }) {
                                ZStack {
                                    LinearGradient(
                                        colors: allConsentsGiven ? [orange, coral] : [Color.gray.opacity(0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    
                                    Text("Add Payment Method")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .cornerRadius(28)
                            }
                            .disabled(!allConsentsGiven || isProcessing)
                            .padding(.horizontal, 24)
                        }
                        
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
        .alert("Stake Created Successfully!", isPresented: $showSuccess) {
            Button("Continue") {
                // Navigate to dashboard
                dismiss()
            }
        } message: {
            Text("Your payment method has been saved securely. You'll only be charged if you exceed your daily limit.")
        }
        .sheet(isPresented: $showConsentDetails) {
            ConsentDetailsView()
        }
    }
    
    // MARK: - Computed Properties
    private var allConsentsGiven: Bool {
        return hasConsented && understandsCharges && acceptsTerms
    }
    
    // MARK: - Actions
    private func setupApplePay() {
        isProcessing = true
        
        paymentManager.presentApplePaySetup(for: stakeAmount) { result in
            switch result {
            case .success(let paymentMethodId):
                // Create the stake with the payment method
                createStake(with: paymentMethodId)
                
            case .failure(let error):
                isProcessing = false
                errorMessage = error.localizedDescription
                showError = true
                
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }
    
    private func createStake(with paymentMethodId: String) {
        // Store consent record
        let consentRecord = ConsentRecord(
            userId: "current_user_id", // Get from auth
            stakeId: UUID().uuidString,
            consentedAt: Date(),
            stakeAmount: stakeAmount,
            dailyLimit: dailyTimeLimit,
            paymentMethodId: paymentMethodId,
            consentText: "User consented to $\(Int(stakeAmount)) charge when exceeding \(formatTimeLimit(dailyTimeLimit)) daily limit"
        )
        
        // Save consent (you'd send this to your backend)
        saveConsentRecord(consentRecord)
        
        // Create the stake
        let timeInSeconds = dailyTimeLimit * 60
        let _ = persistenceManager.createStake(
            selectedApps: selectedApps,
            dailyTimeLimit: timeInSeconds,
            stakeAmount: stakeAmount,
            duration: stakeDuration
        )
        
        isProcessing = false
        showSuccess = true
        
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
    
    private func saveConsentRecord(_ record: ConsentRecord) {
        // Send to backend to store consent record
        // This is critical for compliance and dispute resolution
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

// MARK: - Supporting Views - FIXED iOS 17.0 compatibility
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

struct ApplePayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
        button.cornerRadius = 28
        return button
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
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
                
                Text("Setting up secure payment...")
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

struct ConsentDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        NavigationStack {
            ZStack {
                blackBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Payment Terms & Conditions")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundColor(lightGray)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            DetailSection(
                                title: "When You'll Be Charged",
                                content: """
                                • Only when you exceed your daily screen time limit
                                • Maximum of one charge per day
                                • Charges are processed automatically
                                • Amount matches your stake ($X per violation)
                                """
                            )
                            
                            DetailSection(
                                title: "Your Rights",
                                content: """
                                • 24-hour window to dispute any charge
                                • Cancel your stake anytime (future charges only)
                                • Full transaction history available
                                • Email receipts for every charge
                                """
                            )
                            
                            DetailSection(
                                title: "Data Security",
                                content: """
                                • Card details stored securely by Stripe
                                • We never see or store your full card number
                                • Apple Pay adds additional biometric security
                                • PCI DSS compliant payment processing
                                """
                            )
                            
                            DetailSection(
                                title: "Charge Limits",
                                content: """
                                • Daily cap: Maximum stake amount per day
                                • Monthly cap: 30x your stake amount
                                • Automatic pause if unusual activity detected
                                • No hidden fees or additional charges
                                """
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(coral)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(coral)
            
            Text(content)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(lightGray.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Consent Record Model
struct ConsentRecord: Codable {
    let userId: String
    let stakeId: String
    let consentedAt: Date
    let stakeAmount: Double
    let dailyLimit: Double
    let paymentMethodId: String
    let consentText: String
}

#Preview {
    ApplePaySetupView(
        selectedApps: Array(SocialApp.availableApps.prefix(2)),
        stakeAmount: 10,
        dailyTimeLimit: 120,
        stakeDuration: 7
    )
}