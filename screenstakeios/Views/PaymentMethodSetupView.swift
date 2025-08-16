//
//  PaymentMethodSetupView.swift
//  screenstakeios
//
//  Initial payment method setup (different from stake payment)
//

import SwiftUI

struct PaymentMethodSetupView: View {
    let user: UserAccount
    @EnvironmentObject var authManager: AuthManager
    
    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Brand colors
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let peach = Color(hex: "f4bda4")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    var body: some View {
        ZStack {
            blackBg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(coral)
                        
                        VStack(spacing: 8) {
                            Text("Add Payment Method")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(lightGray)
                            
                            Text("Add a payment method to start creating stakes. We'll only charge you if you exceed your limits.")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Welcome message
                    VStack(spacing: 12) {
                        Text("Welcome, \(user.firstName)! 👋")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundColor(coral)
                        
                        Text("You're almost ready to start your first stake")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.8))
                    }
                    
                    // Security Notice
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(coral)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Secure & Encrypted")
                                .font(.system(.footnote, design: .rounded, weight: .semibold))
                                .foregroundColor(lightGray)
                            
                            Text("Your payment info is protected by bank-level encryption")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .stroke(coral.opacity(0.2), lineWidth: 1)
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
                                .onChange(of: cardNumber) { _, newValue in
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
                                    .onChange(of: expiryDate) { _, newValue in
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
                                    .onChange(of: cvv) { _, newValue in
                                        cvv = String(newValue.filter { $0.isNumber }.prefix(4))
                                    }
                            }
                        }
                        
                        // Cardholder Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cardholder Name")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(lightGray)
                            
                            TextField(user.fullName, text: $cardholderName)
                                .textFieldStyle(CardInputStyle())
                                .textContentType(.name)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .scrollIndicators(.hidden)
            
            // Bottom Actions
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Add Payment Method Button
                    Button(action: {
                        addPaymentMethod()
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
                                    Text("Add Payment Method")
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
                    
                    // Skip for now option
                    Button(action: {
                        // For demo purposes, let them skip and add later
                        authManager.logout()
                    }) {
                        Text("I'll add this later")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(peach.opacity(0.8))
                            .padding(.vertical, 12)
                    }
                    .disabled(isProcessing)
                }
                .padding(.bottom, 34)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Pre-fill cardholder name
            cardholderName = user.fullName
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
    private func addPaymentMethod() {
        Task {
            await processPaymentMethod()
        }
    }
    
    @MainActor
    private func processPaymentMethod() async {
        isProcessing = true
        
        do {
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
            
            // Success - AuthManager will update state automatically
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
        } catch {
            errorMessage = "Failed to add payment method. Please check your card details."
            showError = true
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        isProcessing = false
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
}

#Preview {
    PaymentMethodSetupView(user: UserAccount(
        email: "test@example.com",
        firstName: "John",
        lastName: "Doe",
        createdAt: Date(),
        isEmailVerified: true,
        hasPaymentMethod: false
    ))
}