//
//  AuthView.swift
//  screenstakeios
//
//  Registration and login interface
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLogin = true
    @State private var registrationData = RegistrationData()
    @State private var loginData = LoginData()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
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
                        .frame(height: 60)
                    
                    // Logo and Header
                    VStack(spacing: 20) {
                        Image("ScreenStakeLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200)
                        
                        VStack(spacing: 8) {
                            Text(isLogin ? "Welcome Back" : "Create Account")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(lightGray)
                            
                            Text(isLogin ? "Sign in to manage your stakes" : "Join thousands taking control of their screen time")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Form Toggle
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isLogin = true
                            }
                        }) {
                            Text("Sign In")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(isLogin ? .white : lightGray.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isLogin ? coral : Color.clear)
                                )
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isLogin = false
                            }
                        }) {
                            Text("Sign Up")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(!isLogin ? .white : lightGray.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(!isLogin ? coral : Color.clear)
                                )
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        if isLogin {
                            // Login Form
                            VStack(spacing: 16) {
                                AuthTextField(
                                    title: "Email",
                                    placeholder: "your@email.com",
                                    text: $loginData.email,
                                    keyboardType: .emailAddress
                                )
                                
                                AuthTextField(
                                    title: "Password",
                                    placeholder: "••••••••",
                                    text: $loginData.password,
                                    isSecure: true
                                )
                            }
                        } else {
                            // Registration Form
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    AuthTextField(
                                        title: "First Name",
                                        placeholder: "John",
                                        text: $registrationData.firstName
                                    )
                                    
                                    AuthTextField(
                                        title: "Last Name",
                                        placeholder: "Doe",
                                        text: $registrationData.lastName
                                    )
                                }
                                
                                AuthTextField(
                                    title: "Email",
                                    placeholder: "your@email.com",
                                    text: $registrationData.email,
                                    keyboardType: .emailAddress
                                )
                                
                                AuthTextField(
                                    title: "Password",
                                    placeholder: "At least 8 characters",
                                    text: $registrationData.password,
                                    isSecure: true
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Submit Button
                    Button(action: {
                        submitForm()
                    }) {
                        ZStack {
                            LinearGradient(
                                colors: isFormValid ? [orange, coral] : [Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isLogin ? "Sign In" : "Create Account")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 24)
                    
                    // Terms and Privacy (for registration)
                    if !isLogin {
                        Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(lightGray.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                        .frame(height: 80)
                }
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        if isLogin {
            return loginData.isValid
        } else {
            return registrationData.isValid
        }
    }
    
    // MARK: - Actions
    private func submitForm() {
        Task {
            await processAuth()
        }
    }
    
    @MainActor
    private func processAuth() async {
        isLoading = true
        
        do {
            if isLogin {
                try await authManager.login(with: loginData)
            } else {
                try await authManager.register(with: registrationData)
            }
            
            // Success handled by AuthManager state changes
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
        } catch {
            errorMessage = isLogin ? 
                "Invalid email or password. Please try again." :
                "Failed to create account. Please try again."
            showError = true
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        isLoading = false
    }
}

// MARK: - Custom Text Field
struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(lightGray)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
                }
            }
            .font(.system(.body, design: .rounded))
            .foregroundColor(lightGray)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AuthView()
}