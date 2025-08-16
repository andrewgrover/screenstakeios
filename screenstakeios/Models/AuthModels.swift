//
//  AuthModels.swift
//  screenstakeios
//
//  Authentication and user account models
//

import Foundation

// MARK: - User Account
struct UserAccount: Identifiable, Codable {
    let id = UUID()
    let email: String
    let firstName: String
    let lastName: String
    let createdAt: Date
    var isEmailVerified: Bool
    var hasPaymentMethod: Bool
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

// MARK: - Payment Method
struct PaymentMethod: Identifiable, Codable {
    let id = UUID()
    let stripePaymentMethodId: String // Stripe's payment method ID
    let cardLast4: String
    let cardBrand: String // "visa", "mastercard", etc.
    let expiryMonth: Int
    let expiryYear: Int
    let isDefault: Bool
    let createdAt: Date
    
    var displayName: String {
        return "\(cardBrand.capitalized) •••• \(cardLast4)"
    }
    
    var isExpired: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        return expiryYear < currentYear || (expiryYear == currentYear && expiryMonth < currentMonth)
    }
}

// MARK: - Authentication State
enum AuthState {
    case loading
    case unauthenticated
    case authenticated(UserAccount)
    case needsEmailVerification(UserAccount)
    case needsPaymentMethod(UserAccount)
}

// MARK: - Registration Data
struct RegistrationData {
    var email: String = ""
    var password: String = ""
    var firstName: String = ""
    var lastName: String = ""
    
    var isValid: Bool {
        return !email.isEmpty && 
               email.contains("@") && 
               password.count >= 8 && 
               !firstName.isEmpty && 
               !lastName.isEmpty
    }
}

// MARK: - Login Data
struct LoginData {
    var email: String = ""
    var password: String = ""
    
    var isValid: Bool {
        return !email.isEmpty && email.contains("@") && !password.isEmpty
    }
}