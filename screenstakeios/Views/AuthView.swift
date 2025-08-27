//
//  AuthView.swift
//  screenstakeios
//
//  Updated with SMS verification support - ALL iOS 17.0 compatibility errors fixed
//

import SwiftUI

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
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : keyboardType == .numberPad ? .telephoneNumber : .none)
                }
            }
            .font(.system(.body, design: .rounded))
            .foregroundColor(lightGray)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                // FIXED: Replaced .fill() with .foregroundColor() and .overlay()
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct AuthView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
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
                                        .foregroundColor(isLogin ? coral : Color.clear)
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
                                        .foregroundColor(!isLogin ? coral : Color.clear)
                                )
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundColor(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    
                    // Registration Method Toggle (only for signup)
                    if !isLogin {
                        VStack(spacing: 12) {
                            Text("Sign up with")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                            
                            HStack(spacing: 12) {
                                ForEach(RegistrationMethod.allCases, id: \.self) { method in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            registrationData.method = method
                                            loginData.method = method
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: method.icon)
                                                .font(.system(size: 16, weight: .medium))
                                            
                                            Text(method.displayName)
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        }
                                        .foregroundColor(registrationData.method == method ? .white : lightGray.opacity(0.7))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .foregroundColor(registrationData.method == method ? coral : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(coral.opacity(0.5), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        if isLogin {
                            // Login Form
                            VStack(spacing: 16) {
                                if loginData.method == .email {
                                    AuthTextField(
                                        title: "Email",
                                        placeholder: "your@email.com",
                                        text: $loginData.email,
                                        keyboardType: .emailAddress
                                    )
                                } else {
                                    AuthTextField(
                                        title: "Phone Number",
                                        placeholder: "+1 (555) 123-4567",
                                        text: $loginData.phoneNumber,
                                        keyboardType: .numberPad
                                    )
                                    // FIXED: Changed from iOS 17+ syntax to iOS 16+ compatible
                                    .onChange(of: loginData.phoneNumber) { newValue in
                                        loginData.phoneNumber = formatPhoneNumber(newValue)
                                    }
                                }
                                
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
                                
                                if registrationData.method == .email {
                                    AuthTextField(
                                        title: "Email",
                                        placeholder: "your@email.com",
                                        text: $registrationData.email,
                                        keyboardType: .emailAddress
                                    )
                                } else {
                                    AuthTextField(
                                        title: "Phone Number",
                                        placeholder: "+1 (555) 123-4567",
                                        text: $registrationData.phoneNumber,
                                        keyboardType: .numberPad
                                    )
                                    // FIXED: Changed from iOS 17+ syntax to iOS 16+ compatible
                                    .onChange(of: registrationData.phoneNumber) { newValue in
                                        registrationData.phoneNumber = formatPhoneNumber(newValue)
                                    }
                                }
                                
                                if registrationData.method == .email {
                                    AuthTextField(
                                        title: "Password",
                                        placeholder: "At least 6 characters",
                                        text: $registrationData.password,
                                        isSecure: true
                                    )
                                }
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
                if loginData.method == .email {
                    try await authManager.login(with: loginData)
                } else {
                    // Phone login not implemented yet - would need separate flow
                    errorMessage = "Phone login coming soon! Use email for now."
                    showError = true
                }
            } else {
                try await authManager.register(with: registrationData)
            }
            
            // Success handled by AuthManager state changes
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
        } catch {
            errorMessage = isLogin ? 
                "Invalid credentials. Please try again." :
                "Failed to create account. Please try again."
            showError = true
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Functions
    private func formatPhoneNumber(_ input: String) -> String {
        // Remove all non-digit characters first
        let digits = input.filter { $0.isNumber }
        
        // Limit to 10 digits (US phone numbers without country code)
        let maxLength = 10
        let truncated = String(digits.prefix(maxLength))
        
        if truncated.isEmpty {
            return ""
        }
        
        // Format as +1 (XXX) XXX-XXXX
        if truncated.count <= 3 {
            return "+1 (\(truncated)"
        } else if truncated.count <= 6 {
            let area = String(truncated.prefix(3))
            let exchange = String(truncated.dropFirst(3))
            return "+1 (\(area)) \(exchange)"
        } else {
            let area = String(truncated.prefix(3))
            let exchange = String(truncated.dropFirst(3).prefix(3))
            let number = String(truncated.dropFirst(6))
            return "+1 (\(area)) \(exchange)-\(number)"
        }
    }
}

#Preview {
    AuthView()
}