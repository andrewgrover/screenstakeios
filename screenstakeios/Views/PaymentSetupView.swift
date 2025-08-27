//
//  PaymentSetupView.swift
//  screenstakeios
//
//  Credit card setup view before creating stakes - Fixed iOS compatibility
//

import SwiftUI

struct PaymentSetupView: View {
    let selectedApps: [SocialApp]
    let stakeAmount: Double
    let dailyTimeLimit: Double
    let stakeDuration: Int
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager()
    @StateObject private var persistenceManager = PersistenceManager.shared
    
    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
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
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(coral)
                            
                            Text("Add Payment Method")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(lightGray)
                            
                            Text("Your card will only be charged if you exceed your daily time limit")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Security Notice
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundColor(coral)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Secure Payment Processing")
                                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                                    .foregroundColor(lightGray)
                                
                                Text("Powered by Stripe • Your card details are encrypted")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(lightGray.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(coral.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        
                        // Card Form
                        VStack(spacing: 20) {
                            // Card Number
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Card Number")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(lightGray)
                                
                                TextField("1234 5678 9012 3456", text: $cardNumber)
                                    .textFieldStyle(CardInputStyle())
                                    .keyboardType(.numberPad)
                                    .onChange(of: cardNumber) { newValue in
                                        cardNumber = formatCardNumber(newValue)
                                    }
                            }
                            
                            // Expiry and CVV
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Expiry Date")
                                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                                        .foregroundColor(lightGray)
                                    
                                    TextField("MM/YY", text: $expiryDate)
                                        .textFieldStyle(CardInputStyle())
                                        .keyboardType(.numberPad)
                                        .onChange(of: expiryDate) { newValue in
                                            expiryDate = formatExpiryDate(newValue)
                                        }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CVV")
                                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                                        .foregroundColor(lightGray)
                                    
                                    TextField("123", text: $cvv)
                                        .textFieldStyle(CardInputStyle())
                                        .keyboardType(.numberPad)
                                        .onChange(of: cvv) { newValue in
                                            cvv = String(newValue.filter { $0.isNumber }.prefix(4))
                                        }
                                }
                            }
                            
                            // Cardholder Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cardholder Name")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(lightGray)
                                
                                TextField("John Doe", text: $cardholderName)
                                    .textFieldStyle(CardInputStyle())
                                    .textContentType(.name)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Stake Summary
                        VStack(spacing: 16) {
                            Text("Your Stake Details")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(lightGray)
                            
                            VStack(spacing: 12) {
                                StakeSummaryRow(
                                    icon: "dollarsign.circle.fill",
                                    title: "Amount at Risk",
                                    value: "$\(Int(stakeAmount))",
                                    highlight: true
                                )
                                
                                StakeSummaryRow(
                                    icon: "clock.fill",
                                    title: "Daily Limit",
                                    value: formatTimeLimit(dailyTimeLimit)
                                )
                                
                                StakeSummaryRow(
                                    icon: "calendar",
                                    title: "Duration",
                                    value: "\(stakeDuration) day\(stakeDuration == 1 ? "" : "s")"
                                )
                                
                                StakeSummaryRow(
                                    icon: "apps.iphone",
                                    title: "Apps",
                                    value: selectedApps.map { $0.displayName }.joined(separator: ", ")
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundColor(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(coral.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 120)
                    }
                }
                .scrollIndicators(.hidden)
                
                // Bottom Actions
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Create Stake Button
                        Button(action: {
                            createStakeWithPayment()
                        }) {
                            ZStack {
                                LinearGradient(
                                    colors: isFormValid ? [orange, coral] : [Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    HStack(spacing: 8) {
                                        Text("Create Stake")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .cornerRadius(28)
                            .shadow(
                                color: isFormValid ? orange.opacity(0.3) : .clear,
                                radius: 20,
                                x: 0,
                                y: 10
                            )
                        }
                        .disabled(!isFormValid || isProcessing)
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
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Stake Created!", isPresented: $showSuccess) {
            Button("Continue") {
                // Navigate to main app or stakes dashboard
                dismiss()
            }
        } message: {
            Text("Your stake is now active! We'll monitor your usage and only charge your card if you exceed the limit.")
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !cardNumber.isEmpty &&
               cardNumber.count >= 19 && // "1234 5678 9012 3456"
               !expiryDate.isEmpty &&
               expiryDate.count == 5 && // "MM/YY"
               !cvv.isEmpty &&
               cvv.count >= 3 &&
               !cardholderName.isEmpty
    }
    
    // MARK: - Actions
    private func createStakeWithPayment() {
        Task {
            await processPaymentAndCreateStake()
        }
    }
    
    @MainActor
    private func processPaymentAndCreateStake() async {
        isProcessing = true
        
        do {
            // Simulate Stripe tokenization
            try await Task.sleep(for: .seconds(2))
            
            // Create card details
            let cardDetails = CardDetails(
                last4: String(cardNumber.suffix(4)),
                brand: detectCardBrand(cardNumber),
                expiryMonth: Int(String(expiryDate.prefix(2))) ?? 1,
                expiryYear: 2000 + (Int(String(expiryDate.suffix(2))) ?? 24)
            )
            
            // Add payment method
            try await authManager.addPaymentMethod(
                stripeToken: "tok_" + UUID().uuidString,
                cardDetails: cardDetails
            )
            
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
            
            // Haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
        } catch {
            isProcessing = false
            errorMessage = "Failed to process payment. Please check your card details and try again."
            showError = true
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
    }
    
    // MARK: - Helper Functions
    private func formatCardNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let maxLength = 16
        let truncated = String(digits.prefix(maxLength))
        
        var formatted = ""
        for (index, character) in truncated.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        return formatted
    }
    
    private func formatExpiryDate(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let maxLength = 4
        let truncated = String(digits.prefix(maxLength))
        
        if truncated.count >= 2 {
            let month = String(truncated.prefix(2))
            let year = String(truncated.dropFirst(2))
            return month + "/" + year
        }
        return truncated
    }
    
    private func detectCardBrand(_ cardNumber: String) -> String {
        let digits = cardNumber.filter { $0.isNumber }
        let firstDigit = digits.first
        
        switch firstDigit {
        case "4": return "visa"
        case "5": return "mastercard"
        case "3": return "amex"
        default: return "unknown"
        }
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
}

// MARK: - Custom Text Field Style
struct CardInputStyle: TextFieldStyle {
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(.body, design: .rounded))
            .foregroundColor(lightGray)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Stake Summary Row
struct StakeSummaryRow: View {
    let icon: String
    let title: String
    let value: String
    var highlight: Bool = false
    
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
                .font(.system(.subheadline, design: .rounded, weight: highlight ? .bold : .semibold))
                .foregroundColor(highlight ? coral : lightGray)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    PaymentSetupView(
        selectedApps: Array(SocialApp.availableApps.prefix(2)),
        stakeAmount: 10,
        dailyTimeLimit: 120,
        stakeDuration: 7
    )
}