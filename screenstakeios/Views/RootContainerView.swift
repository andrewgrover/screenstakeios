//
//  RootContainerView.swift
//  screenstakeios
//
//  Simple auth bypass for development
//

import SwiftUI

struct RootContainerView: View {
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var authManager = FirebaseAuthManager()
    
    // 🚀 TOGGLE THIS TO BYPASS AUTH
    private let skipAuth = true
    
    var body: some View {
        Group {
            #if DEBUG
            if skipAuth {
                // Skip directly to dashboard for development
                MainDashboardView()
                    .environmentObject(persistenceManager)
                    .environmentObject(authManager)
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
            
        case .authenticated(let user):
            // Show stakes dashboard
            MainDashboardView()
                .environmentObject(persistenceManager)
                .environmentObject(authManager)
        }
    }
}

// MARK: - Simple Dashboard (until we fix StakesDashboardView)
struct MainDashboardView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @State private var showingNewStake = false
    
    // Brand colors
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    var body: some View {
        NavigationStack {
            ZStack {
                blackBg.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "target")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundColor(coral)
                        
                        VStack(spacing: 12) {
                            Text("Screenstake Dashboard")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(lightGray)
                            
                            Text("Auth bypassed for development")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.7))
                        }
                    }
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        Button(action: {
                            showingNewStake = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Create Your First Stake")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [orange, coral],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: orange.opacity(0.3), radius: 20, x: 0, y: 10)
                        }
                        .padding(.horizontal, 40)
                        
                        // Debug info
                        VStack(spacing: 8) {
                            Text("🚀 Development Mode")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(.yellow)
                            
                            Text("Set skipAuth = false to test authentication")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingNewStake) {
            AppSelectionView()
        }
    }
}

#Preview {
    RootContainerView()
}