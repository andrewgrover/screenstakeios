//
//  FirebaseEmailVerificationView.swift
//  screenstakeios
//
//  Firebase email verification interface - Fixed iOS compatibility
//

import SwiftUI

struct FirebaseEmailVerificationView: View {
    let user: UserAccount
    @EnvironmentObject var authManager: FirebaseAuthManager
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isResending = false
    @State private var showSuccess = false
    @State private var emailsSent = 0
    
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
                        
                        Text("We sent a verification link to")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.8))
                        
                        Text(user.email ?? "Your email")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundColor(coral)
                        
                        VStack(spacing: 8) {
                            Text("Click the link in your email to verify your account")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            if emailsSent > 0 {
                                Text("📧 \(emailsSent) email(s) sent")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(coral.opacity(0.8))
                            }
                        }
                    }
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                // Email troubleshooting tips
                VStack(spacing: 12) {
                    Text("Not seeing the email?")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(lightGray.opacity(0.9))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        EmailTipRow(icon: "magnifyingglass", text: "Check your spam/junk folder")
                        EmailTipRow(icon: "folder", text: "Look in Promotions tab (Gmail)")
                        EmailTipRow(icon: "clock", text: "Wait 2-3 minutes for delivery")
                        EmailTipRow(icon: "envelope.badge", text: "Check 'All Mail' folder")
                    }
                }
                .padding(.horizontal, 24)
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
                
                // Check Verification Button
                Button(action: {
                    checkEmailVerification()
                }) {
                    ZStack {
                        LinearGradient(
                            colors: [orange, coral],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("I've Verified My Email")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .cornerRadius(28)
                    .shadow(color: orange.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)
                
                // Resend Email
                VStack(spacing: 12) {
                    Button(action: {
                        resendEmail()
                    }) {
                        HStack(spacing: 8) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: coral))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Resend Verification Email")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            }
                        }
                        .foregroundColor(coral)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(coral, lineWidth: 1)
                        )
                    }
                    .disabled(isResending || isLoading)
                    
                    if emailsSent > 2 {
                        Text("Try a different email address if issues persist")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
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
        .alert("Email Sent!", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("Check your email (including spam folder) for the verification link.")
        }
        .onAppear {
            // Send initial email if this is the first time
            if emailsSent == 0 {
                resendEmail()
            }
        }
    }
    
    // MARK: - Actions
    private func checkEmailVerification() {
        Task {
            await processEmailCheck()
        }
    }
    
    @MainActor
    private func processEmailCheck() async {
        isLoading = true
        
        do {
            try await authManager.checkEmailVerification()
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
        } catch {
            errorMessage = "Email not verified yet. Please click the link in your email first, then try again."
            showError = true
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        isLoading = false
    }
    
    private func resendEmail() {
        Task {
            await processResend()
        }
    }
    
    @MainActor
    private func processResend() async {
        isResending = true
        
        do {
            try await authManager.sendVerificationEmail()
            emailsSent += 1
            showSuccess = true
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            errorMessage = "Failed to resend email. Please try again."
            showError = true
        }
        
        isResending = false
    }
}

// Helper view for email tips
struct EmailTipRow: View {
    let icon: String
    let text: String
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(coral)
                .frame(width: 16)
            
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(lightGray.opacity(0.8))
            
            Spacer()
        }
    }
}