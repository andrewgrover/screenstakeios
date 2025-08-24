//
//  StripePaymentManager.swift
//  screenstakeios
//
//  Handles Apple Pay integration with Stripe for stake payments
//

import Foundation
import PassKit
import StripePaymentSheet
import StripeApplePay
import StripePayments
import UIKit

@MainActor
class StripePaymentManager: NSObject, ObservableObject {
    static let shared = StripePaymentManager()
    
    // MARK: - Published Properties
    @Published var isProcessingPayment = false
    @Published var paymentError: PaymentError?
    @Published var savedPaymentMethods: [SavedPaymentMethod] = []
    
    // MARK: - Configuration
    private let merchantIdentifier = "merchant.com.screenstakeios"
    private let countryCode = "US"
    private let currencyCode = "USD"
    
    // Apple Pay configuration
    private lazy var applePayConfig: PKPaymentRequest = {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = countryCode
        request.currencyCode = currencyCode
        return request
    }()
    
    private override init() {
        super.init()
        configureStripe()
    }
    
    // MARK: - Stripe Configuration
    private func configureStripe() {
        // Configure Stripe SDK (publishable key should be loaded from config)
        StripeAPI.defaultPublishableKey = getStripePublishableKey()
    }
    
    private func getStripePublishableKey() -> String {
        // In production, load from secure config or backend
        #if DEBUG
        return "pk_test_51Rxyav3zZzP1OsaVVFpKTuTiBXDOIjWBbkAq3BozAyKQp9XuxsUM24onXA1KWwtMymzKtBs1egkPS0OJlWoK6cWg00LHaLzg19" // Replace with your test key
        #else
        return "pk_live_YOUR_LIVE_KEY" // Replace with your live key
        #endif
    }
    
    // MARK: - Setup Intent (Save Card for Future Use)
    func createSetupIntent(for userId: String) async throws -> SetupIntentResponse {
        // Call your backend to create a SetupIntent
        let endpoint = "\(APIConfig.baseURL)/create-setup-intent"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["user_id": userId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.setupIntentFailed
        }
        
        return try JSONDecoder().decode(SetupIntentResponse.self, from: data)
    }
    
    // MARK: - Apple Pay Setup
    func presentApplePaySetup(
        for stakeAmount: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: applePayConfig.supportedNetworks) else {
            completion(.failure(PaymentError.applePayNotAvailable))
            return
        }
        
        // This is for setup - we're not charging yet
        let setupItem = PKPaymentSummaryItem(
            label: "Save Payment Method",
            amount: NSDecimalNumber.zero,
            type: .final
        )
        
        applePayConfig.paymentSummaryItems = [setupItem]
        
        // Add recurring payment notice
        if #available(iOS 16.0, *) {
            let recurringPayment = PKRecurringPaymentSummaryItem(
                label: "Screenstake Limit Exceeded Fee",
                amount: NSDecimalNumber(value: stakeAmount)
            )
            recurringPayment.intervalUnit = .day
            recurringPayment.intervalCount = 1  // Daily limit

            applePayConfig.recurringPaymentRequest = PKRecurringPaymentRequest(
                paymentDescription: "Charged when daily screen time limit is exceeded",
                regularBilling: recurringPayment,
                managementURL: URL(string: "https://screenstake.com/manage")!
            )
        }
        
        let authController = PKPaymentAuthorizationController(paymentRequest: applePayConfig)

        authController.delegate = self
        authController.present { presented in
            if !presented {
                completion(.failure(PaymentError.applePayPresentationFailed))
            }
        }
        
        self.setupCompletion = completion
    }
    
    // MARK: - Confirm Setup Intent with Apple Pay Token
    private func confirmSetupIntent(
        setupIntentId: String,
        applePayToken: String,
        userId: String
    ) async throws -> SavedPaymentMethod {
        let endpoint = "\(APIConfig.baseURL)/confirm-setup-intent"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "setup_intent_id": setupIntentId,
            "apple_pay_token": applePayToken,
            "user_id": userId
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.confirmationFailed
        }
        
        return try JSONDecoder().decode(SavedPaymentMethod.self, from: data)
    }
    
    // MARK: - Process Stake Charge (When Limit Exceeded)
    func chargeStakeAmount(
        userId: String,
        paymentMethodId: String,
        amount: Double,
        stakeId: String
    ) async throws -> ChargeResult {
        let endpoint = "\(APIConfig.baseURL)/charge-stake"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ChargeRequest(
            userId: userId,
            paymentMethodId: paymentMethodId,
            amount: amount,
            stakeId: stakeId,
            metadata: [
                "type": "stake_limit_exceeded",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.networkError
        }
        
        if httpResponse.statusCode == 402 {
            // Requires additional authentication (3DS)
            let authRequired = try JSONDecoder().decode(AuthenticationRequired.self, from: data)
            throw PaymentError.authenticationRequired(clientSecret: authRequired.clientSecret)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PaymentError.chargeFailed
        }
        
        return try JSONDecoder().decode(ChargeResult.self, from: data)
    }
    
    // MARK: - Handle 3DS Authentication
    func handle3DSAuthentication(clientSecret: String) async throws {
        // Present 3DS challenge using Stripe SDK
        try await withCheckedThrowingContinuation { continuation in
            let params = STPPaymentIntentParams(clientSecret: clientSecret)
            STPPaymentHandler.shared().confirmPayment(
                withParams: params,
                authenticationContext: self
            ) { status, _, error in
                switch status {
                case .succeeded:
                    continuation.resume()
                case .failed:
                    continuation.resume(throwing: error ?? PaymentError.authenticationFailed)
                case .canceled:
                    continuation.resume(throwing: PaymentError.authenticationCanceled)
                @unknown default:
                    continuation.resume(throwing: PaymentError.unknown)
                }
            }
        }
    }
    
    // MARK: - Load Saved Payment Methods
    func loadSavedPaymentMethods(for userId: String) async throws {
        let endpoint = "\(APIConfig.baseURL)/payment-methods/\(userId)"
        
        let request = URLRequest(url: URL(string: endpoint)!)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.loadMethodsFailed
        }
        
        savedPaymentMethods = try JSONDecoder().decode([SavedPaymentMethod].self, from: data)
    }
    
    // MARK: - Remove Payment Method
    func removePaymentMethod(_ methodId: String, userId: String) async throws {
        let endpoint = "\(APIConfig.baseURL)/payment-methods/\(methodId)"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["user_id": userId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.removeMethodFailed
        }
        
        savedPaymentMethods.removeAll { $0.id == methodId }
    }
    
    // MARK: - Private Properties
    private var setupCompletion: ((Result<String, Error>) -> Void)?
}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension StripePaymentManager: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        Task {
            do {
                // Convert Apple Pay token to base64 string
                let tokenData = payment.token.paymentData
                let tokenString = tokenData.base64EncodedString()
                
                // Get current user ID
                guard let userId = await getCurrentUserId() else {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    return
                }
                
                // Create setup intent first
                let setupIntent = try await createSetupIntent(for: userId)
                
                // Confirm with Apple Pay token
                let savedMethod = try await confirmSetupIntent(
                    setupIntentId: setupIntent.id,
                    applePayToken: tokenString,
                    userId: userId
                )
                
                savedPaymentMethods.append(savedMethod)
                
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                setupCompletion?(.success(savedMethod.id))
            } catch {
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                setupCompletion?(.failure(error))
            }
        }
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
    
    private func getCurrentUserId() async -> String? {
        // Get from your auth manager
        return "current_user_id" // Replace with actual implementation
    }
}

// MARK: - STPAuthenticationContext
extension StripePaymentManager: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        // Return the top-most view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return UIViewController()
        }
        
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        return topController
    }
}

// MARK: - Data Models
struct SetupIntentResponse: Codable {
    let id: String
    let clientSecret: String
    let ephemeralKey: String
    let customerId: String
}

struct SavedPaymentMethod: Codable, Identifiable {
    let id: String
    let type: String // "apple_pay", "card"
    let last4: String?
    let brand: String?
    let isDefault: Bool
    let createdAt: Date
}

struct ChargeRequest: Codable {
    let userId: String
    let paymentMethodId: String
    let amount: Double
    let stakeId: String
    let metadata: [String: String]
}

struct ChargeResult: Codable {
    let chargeId: String
    let status: String
    let amount: Double
    let receiptUrl: String?
}

struct AuthenticationRequired: Codable {
    let clientSecret: String
    let paymentIntentId: String
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case applePayNotAvailable
    case applePaySetupFailed
    case applePayPresentationFailed
    case setupIntentFailed
    case confirmationFailed
    case chargeFailed
    case authenticationRequired(clientSecret: String)
    case authenticationFailed
    case authenticationCanceled
    case loadMethodsFailed
    case removeMethodFailed
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .applePayNotAvailable:
            return "Apple Pay is not available on this device"
        case .applePaySetupFailed:
            return "Failed to set up Apple Pay"
        case .applePayPresentationFailed:
            return "Failed to present Apple Pay"
        case .setupIntentFailed:
            return "Failed to create payment setup"
        case .confirmationFailed:
            return "Failed to confirm payment method"
        case .chargeFailed:
            return "Failed to process charge"
        case .authenticationRequired:
            return "Additional authentication required"
        case .authenticationFailed:
            return "Authentication failed"
        case .authenticationCanceled:
            return "Authentication was canceled"
        case .loadMethodsFailed:
            return "Failed to load payment methods"
        case .removeMethodFailed:
            return "Failed to remove payment method"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - API Configuration
struct APIConfig {
    #if DEBUG
    static let baseURL = "https://api-dev.screenstake.com"
    #else
    static let baseURL = "https://api.screenstake.com"
    #endif
}
