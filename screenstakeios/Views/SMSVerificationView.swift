//
//  SMSVerificationView.swift
//  screenstakeios
//
//  SMS verification interface
//

import SwiftUI

struct SMSVerificationView: View {
    let user: UserAccount
    let verificationId: String
    @EnvironmentObject var authManager: FirebaseAuthManager
    
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
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundColor(coral)
                    
                    VStack(spacing: 12) {
                        Text("Enter Verification Code")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundColor(lightGray)
                        
                        Text("We sent a 6-digit code to")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.8))
                        
                        Text(user.phoneNumber ?? "")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundColor(coral)
                    }
                    .multilineTextAlignment(.center)
                }
                
                // Verification Code Input
                VStack(spacing: 16) {
                    TextField("000000", text: $verificationCode)
                        .font(.system(.title, design: .monospaced, weight: .medium))
                        .foregroundColor(lightGray)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: verificationCode) { _, newValue in
                            // Limit to 6 digits and auto-submit when complete
                            verificationCode = String(newValue.filter { $0.isNumber }.prefix(6))
                            
                            if verificationCode.count == 6 {
                                verifyCode()
                            }
                        }
                    
                    Button(action: {
                        verifyCode()
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
                                Text("Verify Code")
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
                
                // Back option
                Button(action: {
                    authManager.logout()
                }) {
                    Text("Use Different Number")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(lightGray.opacity(0.6))
                }
                .padding(.bottom, 34)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                verificationCode = "" // Clear code on error
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    private func verifyCode() {
        Task {
            await processVerification()
        }
    }
    
    @MainActor
    private func processVerification() async {
        isLoading = true
        
        do {
            try await authManager.verifyPhoneCode(verificationId: verificationId, code: verificationCode)
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
        } catch {
            errorMessage = "Invalid verification code. Please try again."
            showError = true
            
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
            try await authManager.resendPhoneVerification(phoneNumber: user.phoneNumber ?? "")
            
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
    SMSVerificationView(
        user: UserAccount(
            email: nil,
            phoneNumber: "+1 (555) 123-4567",
            firstName: "John",
            lastName: "Doe",
            createdAt: Date(),
            isEmailVerified: false,
            isPhoneVerified: false,
            hasPaymentMethod: false,
            registrationMethod: .phone
        ),
        verificationId: "test-verification-id"
    )
}