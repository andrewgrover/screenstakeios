//
//  StripePaymentManager.swift
//  screenstakeios
//
//  Simplified payment manager - All scope issues fixed
//

import Foundation
import PassKit
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
    
    // Completion handler for Apple Pay setup
    private var setupCompletion: ((Result<String, Error>) -> Void)?
    
    private override init() {
        super.init()
        print("🟢 StripePaymentManager initialized")
    }
    
    // MARK: - Apple Pay Setup (Simplified for Development)
    func presentApplePaySetup(
        for stakeAmount: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🍎 Starting Apple Pay setup for amount: $\(stakeAmount)")
        
        // Check if Apple Pay is available
        guard PKPaymentAuthorizationController.canMakePayments() else {
            print("❌ Apple Pay not available on this device")
            completion(.failure(PaymentError.applePayNotAvailable))
            return
        }
        
        // Check if cards are set up
        let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .discover]
        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks) else {
            print("❌ No compatible cards set up in Apple Pay")
            completion(.failure(PaymentError.applePaySetupFailed))
            return
        }
        
        // Create payment request
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.supportedNetworks = supportedNetworks
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        
        // For setup, we create a $0 authorization
        let setupItem = PKPaymentSummaryItem(
            label: "Screenstake Payment Setup",
            amount: NSDecimalNumber.zero,
            type: .final
        )
        paymentRequest.paymentSummaryItems = [setupItem]
        
        // Present Apple Pay
        let authController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        authController.delegate = self
        
        print("🍎 Presenting Apple Pay controller...")
        authController.present { [weak self] presented in
            if presented {
                print("✅ Apple Pay controller presented successfully")
                self?.setupCompletion = completion
            } else {
                print("❌ Failed to present Apple Pay controller")
                completion(.failure(PaymentError.applePayPresentationFailed))
            }
        }
    }
    
    // MARK: - Mock Charge Processing (for development)
    func chargeStakeAmount(
        userId: String,
        paymentMethodId: String,
        amount: Double,
        stakeId: String
    ) async throws -> ChargeResult {
        print("💳 Mock charging stake amount: $\(amount) for user: \(userId)")
        
        // Simulate processing delay
        try await Task.sleep(for: .seconds(1))
        
        // Mock successful charge
        return ChargeResult(
            chargeId: "ch_mock_\(UUID().uuidString)",
            status: "succeeded",
            amount: amount,
            receiptUrl: "https://screenstake.com/receipts/mock"
        )
    }
    func createTestStake(
        userId: String,
        stakeAmount: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🧪 Creating test stake for user: \(userId), amount: $\(stakeAmount)")
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Create mock payment method
            let mockPaymentMethod = SavedPaymentMethod(
                id: "pm_test_\(UUID().uuidString)",
                type: "test_card",
                last4: "4242",
                brand: "visa",
                isDefault: true,
                createdAt: Date()
            )
            
            self.savedPaymentMethods.append(mockPaymentMethod)
            completion(.success(mockPaymentMethod.id))
            
            print("✅ Test stake created successfully")
        }
    }
    
    // MARK: - Load/Save Payment Methods (mock for now)
    func loadSavedPaymentMethods(for userId: String) async throws {
        // Mock loading
        print("📋 Loading saved payment methods for user: \(userId)")
        // In real implementation, this would call your backend
    }
    
    func removePaymentMethod(_ methodId: String, userId: String) async throws {
        savedPaymentMethods.removeAll { $0.id == methodId }
        print("🗑️ Removed payment method: \(methodId)")
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension StripePaymentManager: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        print("💳 Apple Pay payment authorized")
        
        // In a real implementation, you'd send the payment token to your backend
        // For now, we'll simulate success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockPaymentMethod = SavedPaymentMethod(
                id: "pm_apple_pay_\(UUID().uuidString)",
                type: "apple_pay",
                last4: nil,
                brand: "apple_pay",
                isDefault: true,
                createdAt: Date()
            )
            
            self.savedPaymentMethods.append(mockPaymentMethod)
            
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            self.setupCompletion?(.success(mockPaymentMethod.id))
            
            print("✅ Apple Pay setup completed successfully")
        }
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        print("🍎 Apple Pay controller finished")
        controller.dismiss()
    }
}

// MARK: - Data Models
struct SavedPaymentMethod: Codable, Identifiable {
    let id: String
    let type: String // "apple_pay", "card", "test_card"
    let last4: String?
    let brand: String?
    let isDefault: Bool
    let createdAt: Date
    
    var displayName: String {
        if type == "apple_pay" {
            return "Apple Pay"
        } else if let brand = brand?.capitalized, let last4 = last4 {
            return "\(brand) •••• \(last4)"
        } else {
            return "Test Payment Method"
        }
    }
}

// MARK: - Additional Data Models
struct ChargeResult: Codable {
    let chargeId: String
    let status: String
    let amount: Double
    let receiptUrl: String?
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case applePayNotAvailable
    case applePaySetupFailed
    case applePayPresentationFailed
    case authenticationRequired(clientSecret: String)
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .applePayNotAvailable:
            return "Apple Pay is not available on this device"
        case .applePaySetupFailed:
            return "No payment cards are set up in Apple Pay. Please add a card in Settings."
        case .applePayPresentationFailed:
            return "Failed to present Apple Pay"
        case .authenticationRequired(let clientSecret):
            return "Additional authentication required"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - API Configuration (simplified)
struct APIConfig {
    #if DEBUG
    static let baseURL = "https://api-dev.screenstake.com"
    #else
    static let baseURL = "https://api.screenstake.com"
    #endif
}