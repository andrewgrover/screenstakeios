//
//  FirebaseAuthManager.swift
//  screenstakeios
//
//  Firebase Authentication Manager with SMS support
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore

@MainActor
class FirebaseAuthManager: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentFirebaseUser: User?
    @Published var paymentMethods: [PaymentMethod] = []
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user)
            }
        }
        
        checkInitialAuthState()
    }
    
    // MARK: - Auth State Management
    private func checkInitialAuthState() {
        if let user = Auth.auth().currentUser {
            handleAuthStateChange(user)
        } else {
            authState = .unauthenticated
        }
    }
    
    private func handleAuthStateChange(_ user: User?) {
        currentFirebaseUser = user
        
        guard let user = user else {
            authState = .unauthenticated
            return
        }
        
        let userAccount = createUserAccount(from: user)
        
        // Check verification status based on registration method
        if !userAccount.isVerified {
            if userAccount.registrationMethod == .email {
                authState = .needsEmailVerification(userAccount)
            } else {
                // For phone auth, user is automatically verified after SMS verification
                // So this shouldn't happen, but handle it gracefully
                authState = .needsPhoneVerification(userAccount, verificationId: "")
            }
        } else if !userAccount.hasPaymentMethod {
            authState = .needsPaymentMethod(userAccount)
        } else {
            authState = .authenticated(userAccount)
        }
        
        loadPaymentMethods()
    }
    
    // MARK: - Registration
    func register(with data: RegistrationData) async throws {
        print("🔄 Starting registration for: \(data.primaryContact)")
        authState = .loading
        
        if data.method == .email {
            try await registerWithEmail(data)
        } else {
            try await registerWithPhone(data)
        }
    }
    
    private func registerWithEmail(_ data: RegistrationData) async throws {
        let result = try await Auth.auth().createUser(withEmail: data.email, password: data.password)
        print("✅ User created successfully: \(result.user.uid)")
        
        // Update display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = "\(data.firstName) \(data.lastName)"
        try await changeRequest.commitChanges()
        print("✅ Display name updated")
        
        // Send verification email
        print("📧 Attempting to send verification email...")
        try await result.user.sendEmailVerification()
        print("✅ Verification email sent successfully")
        
        // Store additional user data locally
        storeUserData(uid: result.user.uid, data: data)
        print("✅ User data stored locally")
    }
    
    private func registerWithPhone(_ data: RegistrationData) async throws {
        print("📱 Starting phone verification for: \(data.phoneNumber)")
        
        // Send SMS verification
        let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(
            data.phoneNumber,
            uiDelegate: nil
        )
        
        print("✅ SMS verification sent, ID: \(verificationID)")
        
        // Create temporary user account for verification state
        let tempUser = UserAccount(
            email: nil,
            phoneNumber: data.phoneNumber,
            firstName: data.firstName,
            lastName: data.lastName,
            createdAt: Date(),
            isEmailVerified: false,
            isPhoneVerified: false,
            hasPaymentMethod: false,
            registrationMethod: .phone
        )
        
        // Store registration data temporarily
        storeTemporaryRegistrationData(data)
        
        authState = .needsPhoneVerification(tempUser, verificationId: verificationID)
    }
    
    // MARK: - Phone Verification
    func verifyPhoneCode(verificationId: String, code: String) async throws {
        print("📱 Verifying phone code: \(code)")
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: code
        )
        
        let result = try await Auth.auth().signIn(with: credential)
        print("✅ Phone verification successful: \(result.user.uid)")
        
        // Get stored registration data
        if let data = getTemporaryRegistrationData() {
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = "\(data.firstName) \(data.lastName)"
            try await changeRequest.commitChanges()
            
            // Store user data
            storeUserData(uid: result.user.uid, data: data)
            
            // Clear temporary data
            clearTemporaryRegistrationData()
        }
        
        // handleAuthStateChange will be called automatically
    }
    
    func resendPhoneVerification(phoneNumber: String) async throws {
        print("📱 Resending SMS to: \(phoneNumber)")
        
        let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(
            phoneNumber,
            uiDelegate: nil
        )
        
        print("✅ SMS resent, new ID: \(verificationID)")
        
        // Update the verification ID in the current state
        if case .needsPhoneVerification(let user, _) = authState {
            authState = .needsPhoneVerification(user, verificationId: verificationID)
        }
    }
    
    // MARK: - Login
    func login(with data: LoginData) async throws {
        authState = .loading
        
        if data.method == .email {
            let _ = try await Auth.auth().signIn(withEmail: data.email, password: data.password)
        } else {
            // Phone login would require SMS verification too
            throw NSError(domain: "Phone login not implemented yet", code: 400)
        }
        // handleAuthStateChange will be called automatically
    }
    
    // MARK: - Email Verification
    func sendVerificationEmail() async throws {
        guard let user = Auth.auth().currentUser else { 
            print("❌ No current user found")
            throw NSError(domain: "No current user", code: 401)
        }
        
        print("📧 Sending verification email to: \(user.email ?? "unknown")")
        try await user.sendEmailVerification()
        print("✅ Verification email sent successfully")
    }
    
    func checkEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else { 
            print("❌ No current user found")
            throw NSError(domain: "No current user", code: 401)
        }
        
        print("🔄 Checking email verification status...")
        try await user.reload()
        
        if !user.isEmailVerified {
            throw NSError(domain: "Email not verified yet", code: 400)
        }
        
        // handleAuthStateChange will be called automatically
    }
    
    // MARK: - Payment Methods
    func addPaymentMethod(stripeToken: String, cardDetails: CardDetails) async throws {
        guard let user = currentFirebaseUser else { 
            throw NSError(domain: "No current user", code: 401)
        }
        
        // Simulate Stripe integration
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
        savePaymentMethods(for: user.uid)
        
        // Mark user as having payment method
        userDefaults.set(true, forKey: "hasPaymentMethod_\(user.uid)")
        
        // Update auth state
        handleAuthStateChange(user)
    }
    
    func removePaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        guard let user = currentFirebaseUser else { return }
        
        paymentMethods.removeAll { $0.id == paymentMethod.id }
        savePaymentMethods(for: user.uid)
        
        if paymentMethods.isEmpty {
            userDefaults.set(false, forKey: "hasPaymentMethod_\(user.uid)")
            handleAuthStateChange(user)
        }
    }
    
    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
            paymentMethods = []
            clearTemporaryRegistrationData()
            // handleAuthStateChange will be called automatically
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func createUserAccount(from user: User) -> UserAccount {
        let names = user.displayName?.components(separatedBy: " ") ?? ["", ""]
        let firstName = getUserData(uid: user.uid, key: "firstName") ?? names.first ?? ""
        let lastName = getUserData(uid: user.uid, key: "lastName") ?? (names.count > 1 ? names.last ?? "" : "")
        let registrationMethod = RegistrationMethod(rawValue: getUserData(uid: user.uid, key: "registrationMethod") ?? "email") ?? .email
        
        return UserAccount(
            email: user.email,
            phoneNumber: user.phoneNumber,
            firstName: firstName,
            lastName: lastName,
            createdAt: user.metadata.creationDate ?? Date(),
            isEmailVerified: user.isEmailVerified,
            isPhoneVerified: user.phoneNumber != nil, // Phone users are verified after SMS
            hasPaymentMethod: userDefaults.bool(forKey: "hasPaymentMethod_\(user.uid)"),
            registrationMethod: registrationMethod
        )
    }
    
    private func storeUserData(uid: String, data: RegistrationData) {
        userDefaults.set(data.firstName, forKey: "firstName_\(uid)")
        userDefaults.set(data.lastName, forKey: "lastName_\(uid)")
        userDefaults.set(data.method.rawValue, forKey: "registrationMethod_\(uid)")
    }
    
    private func getUserData(uid: String, key: String) -> String? {
        return userDefaults.string(forKey: "\(key)_\(uid)")
    }
    
    // MARK: - Temporary Registration Data (for phone verification)
    private func storeTemporaryRegistrationData(_ data: RegistrationData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "tempRegistrationData")
        }
    }
    
    private func getTemporaryRegistrationData() -> RegistrationData? {
        guard let data = userDefaults.data(forKey: "tempRegistrationData"),
              let decoded = try? JSONDecoder().decode(RegistrationData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    private func clearTemporaryRegistrationData() {
        userDefaults.removeObject(forKey: "tempRegistrationData")
    }
    
    private func loadPaymentMethods() {
        guard let user = currentFirebaseUser else { return }
        
        if let data = userDefaults.data(forKey: "paymentMethods_\(user.uid)"),
           let methods = try? JSONDecoder().decode([PaymentMethod].self, from: data) {
            paymentMethods = methods
        }
    }
    
    private func savePaymentMethods(for uid: String) {
        if let data = try? JSONEncoder().encode(paymentMethods) {
            userDefaults.set(data, forKey: "paymentMethods_\(uid)")
        }
    }
}