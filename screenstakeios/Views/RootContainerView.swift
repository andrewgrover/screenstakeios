//
//  RootContainerView.swift
//  screenstakeios
//

import SwiftUI

struct RootContainerView: View {
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var authManager = AuthManager()
    
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
                // Show email verification screen
                EmailVerificationView(user: user)
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