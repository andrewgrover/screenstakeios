//
//  AuthModels.swift
//  screenstakeios
//
//  Updated with SMS verification support
//

import Foundation

// MARK: - User Account
struct UserAccount: Identifiable, Codable {
    var id = UUID()
    let email: String?
    let phoneNumber: String?
    let firstName: String
    let lastName: String
    let createdAt: Date
    var isEmailVerified: Bool
    var isPhoneVerified: Bool
    var hasPaymentMethod: Bool
    let registrationMethod: RegistrationMethod
    
    // Convenience initializer for email-only users (backwards compatibility)
    init(email: String, firstName: String, lastName: String, createdAt: Date, isEmailVerified: Bool, hasPaymentMethod: Bool) {
        self.id = UUID()
        self.email = email
        self.phoneNumber = nil
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = false
        self.hasPaymentMethod = hasPaymentMethod
        self.registrationMethod = .email
    }
    
    // Full initializer
    init(email: String?, phoneNumber: String?, firstName: String, lastName: String, createdAt: Date, isEmailVerified: Bool, isPhoneVerified: Bool, hasPaymentMethod: Bool, registrationMethod: RegistrationMethod) {
        self.id = UUID()
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
        self.hasPaymentMethod = hasPaymentMethod
        self.registrationMethod = registrationMethod
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var primaryContact: String {
        if registrationMethod == .email {
            return email ?? ""
        } else {
            return phoneNumber ?? ""
        }
    }
    
    var isVerified: Bool {
        return registrationMethod == .email ? isEmailVerified : isPhoneVerified
    }
}

// MARK: - Registration Method
enum RegistrationMethod: String, Codable, CaseIterable {
    case email = "email"
    case phone = "phone"
    
    var displayName: String {
        switch self {
        case .email: return "Email"
        case .phone: return "Phone"
        }
    }
    
    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        }
    }
}

// MARK: - Payment Method
struct PaymentMethod: Identifiable, Codable {
    var id = UUID()
    let stripePaymentMethodId: String
    let cardLast4: String
    let cardBrand: String
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
    case needsPhoneVerification(UserAccount, verificationId: String)
    case needsPaymentMethod(UserAccount)
}

// MARK: - Registration Data
struct RegistrationData: Codable {
    var method: RegistrationMethod = .email
    var email: String = ""
    var phoneNumber: String = ""
    var password: String = ""
    var firstName: String = ""
    var lastName: String = ""
    
    var isValid: Bool {
        let hasValidContact = method == .email ? 
            (!email.isEmpty && email.contains("@")) :
            (!phoneNumber.isEmpty && phoneNumber.count >= 10)
        
        return hasValidContact && 
               password.count >= 6 && 
               !firstName.isEmpty && 
               !lastName.isEmpty
    }
    
    var primaryContact: String {
        return method == .email ? email : phoneNumber
    }
}

// MARK: - Login Data
struct LoginData: Codable {
    var method: RegistrationMethod = .email
    var email: String = ""
    var phoneNumber: String = ""
    var password: String = ""
    
    var isValid: Bool {
        let hasValidContact = method == .email ? 
            (!email.isEmpty && email.contains("@")) :
            (!phoneNumber.isEmpty && phoneNumber.count >= 10)
        
        return hasValidContact && !password.isEmpty
    }
}

// MARK: - Card Details Helper
struct CardDetails {
    let last4: String
    let brand: String
    let expiryMonth: Int
    let expiryYear: Int
}