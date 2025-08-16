//
//  AuthManager.swift
//  screenstakeios
//
//  Handles user authentication and account management
//

import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentUser: UserAccount?
    @Published var paymentMethods: [PaymentMethod] = []
    
    private let keychain = KeychainHelper()
    private let userDefaults = UserDefaults.standard
    
    init() {
        checkAuthState()
    }
    
    // MARK: - Auth State Management
    private func checkAuthState() {
        // Check if user is logged in (simplified - would check token validity in real app)
        if let userData = userDefaults.data(forKey: "current_user"),
           let user = try? JSONDecoder().decode(UserAccount.self, from: userData) {
            currentUser = user
            loadPaymentMethods()
            
            if !user.isEmailVerified {
                authState = .needsEmailVerification(user)
            } else if !user.hasPaymentMethod {
                authState = .needsPaymentMethod(user)
            } else {
                authState = .authenticated(user)
            }
        } else {
            authState = .unauthenticated
        }
    }
    
    // MARK: - Registration
    func register(with data: RegistrationData) async throws {
        authState = .loading
        
        // Simulate API call
        try await Task.sleep(for: .seconds(1.5))
        
        // In real app: Make API call to create account
        let newUser = UserAccount(
            email: data.email,
            firstName: data.firstName,
            lastName: data.lastName,
            createdAt: Date(),
            isEmailVerified: false,
            hasPaymentMethod: false
        )
        
        currentUser = newUser
        saveUser(newUser)
        
        authState = .needsEmailVerification(newUser)
    }
    
    // MARK: - Login
    func login(with data: LoginData) async throws {
        authState = .loading
        
        // Simulate API call
        try await Task.sleep(for: .seconds(1))
        
        // In real app: Authenticate with backend
        // For demo, create a mock user
        let user = UserAccount(
            email: data.email,
            firstName: "Demo",
            lastName: "User",
            createdAt: Date(),
            isEmailVerified: true,
            hasPaymentMethod: false
        )
        
        currentUser = user
        saveUser(user)
        
        authState = user.hasPaymentMethod ? .authenticated(user) : .needsPaymentMethod(user)
    }
    
    // MARK: - Email Verification
    func sendVerificationEmail() async throws {
        // Simulate sending verification email
        try await Task.sleep(for: .seconds(1))
        // In real app: Call API to send verification email
    }
    
    func verifyEmail(code: String) async throws {
        // Simulate email verification
        try await Task.sleep(for: .seconds(1))
        
        guard var user = currentUser else { return }
        user.isEmailVerified = true
        currentUser = user
        saveUser(user)
        
        authState = user.hasPaymentMethod ? .authenticated(user) : .needsPaymentMethod(user)
    }
    
    // MARK: - Payment Methods
    func addPaymentMethod(stripeToken: String, cardDetails: CardDetails) async throws {
        // Simulate adding payment method via Stripe
        try await Task.sleep(for: .seconds(2))
        
        let paymentMethod = PaymentMethod(
            stripePaymentMethodId: "pm_\(UUID().uuidString.prefix(24))",
            cardLast4: cardDetails.last4,
            cardBrand: cardDetails.brand,
            expiryMonth: cardDetails.expiryMonth,
            expiryYear: cardDetails.expiryYear,
            isDefault: paymentMethods.isEmpty,
            createdAt: Date()
        )
        
        paymentMethods.append(paymentMethod)
        savePaymentMethods()
        
        // Update user to reflect they have a payment method
        if var user = currentUser {
            user.hasPaymentMethod = true
            currentUser = user
            saveUser(user)
            authState = .authenticated(user)
        }
    }
    
    func removePaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        // In real app: Call Stripe API to detach payment method
        paymentMethods.removeAll { $0.id == paymentMethod.id }
        savePaymentMethods()
        
        // If no payment methods left, update user state
        if paymentMethods.isEmpty, var user = currentUser {
            user.hasPaymentMethod = false
            currentUser = user
            saveUser(user)
            authState = .needsPaymentMethod(user)
        }
    }
    
    // MARK: - Logout
    func logout() {
        currentUser = nil
        paymentMethods = []
        userDefaults.removeObject(forKey: "current_user")
        userDefaults.removeObject(forKey: "payment_methods")
        keychain.clearAll()
        authState = .unauthenticated
    }
    
    // MARK: - Data Persistence
    private func saveUser(_ user: UserAccount) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: "current_user")
        }
    }
    
    private func loadPaymentMethods() {
        if let data = userDefaults.data(forKey: "payment_methods"),
           let methods = try? JSONDecoder().decode([PaymentMethod].self, from: data) {
            paymentMethods = methods
        }
    }
    
    private func savePaymentMethods() {
        if let data = try? JSONEncoder().encode(paymentMethods) {
            userDefaults.set(data, forKey: "payment_methods")
        }
    }
}

// MARK: - Card Details Helper
struct CardDetails {
    let last4: String
    let brand: String
    let expiryMonth: Int
    let expiryYear: Int
}

// MARK: - Keychain Helper (Simplified)
class KeychainHelper {
    func clearAll() {
        // In real app: Clear sensitive data from keychain
        // This would include access tokens, refresh tokens, etc.
    }
}