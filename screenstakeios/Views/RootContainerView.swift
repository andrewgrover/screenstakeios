//
//  RootContainerView.swift
//  screenstakeios
//
//  Updated for Firebase Authentication
//

import SwiftUI

struct RootContainerView: View {
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var authManager = FirebaseAuthManager()
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                // Show loading screen
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                
            case .unauthenticated:
                // Show auth (login/register)
                AuthView()
                    .environmentObject(authManager)
                
            case .needsEmailVerification(let user):
                // Show Firebase email verification screen
                FirebaseEmailVerificationView(user: user)
                    .environmentObject(authManager)
                
            case .needsPhoneVerification(let user, let verificationId):
                // Show SMS verification screen
                SMSVerificationView(user: user, verificationId: verificationId)
                    .environmentObject(authManager)
                
            case .needsPaymentMethod(let user):
                // Show payment method setup (different from stake payment)
                PaymentMethodSetupView(user: user)
                    .environmentObject(authManager)
                
            case .authenticated(let user):
                // Show main app
                LandingView()
                    .environmentObject(persistenceManager)
                    .environmentObject(authManager)
            }
        }
        .onReceive(authManager.$authState) { newState in
            print("🔄 Auth state changed to: \(newState)")
        }
    }
}

#Preview {
    RootContainerView()
}