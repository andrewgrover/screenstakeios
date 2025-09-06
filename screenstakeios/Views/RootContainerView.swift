//
//  RootContainerView.swift - COMPLETE UPDATED VERSION
//  screenstakeios
//

import SwiftUI

struct RootContainerView: View {
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var authManager = FirebaseAuthManager()
    @StateObject private var trackingService = StakeTrackingService.shared
    
    // 🚀 TOGGLE THIS TO BYPASS AUTH
    private let skipAuth = true
    
    var body: some View {
        Group {
            #if DEBUG
            if skipAuth {
                // Use the new dashboard for development
                StakesDashboardView()
                    .environmentObject(persistenceManager)
                    .environmentObject(authManager)
                    .environmentObject(trackingService)
            } else {
                authFlow
            }
            #else
            authFlow
            #endif
        }
        .onReceive(authManager.$authState) { newState in
            print("🔄 Auth state changed to: \(newState)")
        }
    }
    
    @ViewBuilder
    private var authFlow: some View {
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
            
        case .authenticated(_):
            // Show the new stakes dashboard with tracking service
            StakesDashboardView()
                .environmentObject(persistenceManager)
                .environmentObject(authManager)
                .environmentObject(trackingService)
        }
    }
}

#Preview {
    RootContainerView()
}

