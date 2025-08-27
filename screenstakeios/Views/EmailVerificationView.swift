//
//  EmailVerificationView.swift
//  screenstakeios
//
//  Email verification interface - Fixed iOS compatibility
//

import SwiftUI

struct EmailVerificationView: View {
    let user: UserAccount
    @EnvironmentObject var authManager: AuthManager
    
    @State private var verificationCode: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isResending = false
    
    // Brand colors
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    var body: some View {
        ZStack {
            blackBg.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundColor(coral)
                    
                    VStack(spacing: 12) {
                        Text("Check Your Email")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundColor(lightGray)
                        
                        Text("We sent a verification code to")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.8))
                        
                        Text(user.email ?? "Your email")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundColor(coral)
                    }
                    .multilineTextAlignment(.center)
                }
                
                // Verification Code Input
                VStack(spacing: 16) {
                    TextField("Enter 6-digit code", text: $verificationCode)
                        .font(.system(.title2, design: .monospaced, weight: .medium))
                        .foregroundColor(lightGray)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        // Fixed onChange for iOS 16 compatibility
                        .onChange(of: verificationCode) { newValue in
                            // Limit to 6 digits
                            verificationCode = String(newValue.filter { $0.isNumber }.prefix(6))
                        }
                    
                    Button(action: {
                        verifyEmail()
                    }) {
                        ZStack {
                            LinearGradient(
                                colors: verificationCode.count == 6 ? [orange, coral] : [Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Verify Email")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .cornerRadius(28)
                    }
                    .disabled(verificationCode.count != 6 || isLoading)
                }
                .padding(.horizontal, 24)
                
                // Resend Code
                VStack(spacing: 12) {
                    Text("Didn't receive the code?")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.7))
                    
                    Button(action: {
                        resendCode()
                    }) {
                        if isResending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: coral))
                                .scaleEffect(0.8)
                        } else {
                            Text("Resend Code")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(coral)
                        }
                    }
                    .disabled(isResending || isLoading)
                }
                
                Spacer()
                
                // Logout option
                Button(action: {
                    authManager.logout()
                }) {
                    Text("Use Different Email")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.6))
                }
                .padding(.bottom, 34)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    private func verifyEmail() {
        Task {
            await processVerification()
        }
    }
    
    @MainActor
    private func processVerification() async {
        isLoading = true
        
        do {
            try await authManager.verifyEmail(code: verificationCode)
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
        } catch {
            errorMessage = "Invalid verification code. Please try again."
            showError = true
            verificationCode = ""
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        isLoading = false
    }
    
    private func resendCode() {
        Task {
            await processResend()
        }
    }
    
    @MainActor
    private func processResend() async {
        isResending = true
        
        do {
            try await authManager.sendVerificationEmail()
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            errorMessage = "Failed to resend code. Please try again."
            showError = true
        }
        
        isResending = false
    }
}

#Preview {
    EmailVerificationView(user: UserAccount(
        email: "test@example.com",
        firstName: "John",
        lastName: "Doe",
        createdAt: Date(),
        isEmailVerified: false,
        hasPaymentMethod: false
    ))
}