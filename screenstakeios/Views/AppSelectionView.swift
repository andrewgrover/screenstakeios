//
//  AppSelectionView.swift
//  screenstakeios
//
//  View for selecting social media apps to stake on
//

import SwiftUI

struct AppSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var persistenceManager = PersistenceManager.shared
    
    @State private var selectedApps: Set<SocialApp> = []
    @State private var showingStakeSetup = false
    @State private var animateCards = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Brand colors
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let peach = Color(hex: "f4bda4")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                blackBg
                    .ignoresSafeArea()
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        blackBg,
                        orange.opacity(0.05),
                        blackBg
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .blendMode(.screen)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 16) {
                            Text("Choose Your Apps")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(lightGray)
                                .multilineTextAlignment(.center)
                            
                            Text("Select the social media apps you want to limit. You can choose multiple apps for your stake.")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(lightGray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Apps Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(SocialApp.availableApps) { app in
                                AppSelectionCard(
                                    app: app,
                                    isSelected: selectedApps.contains(app),
                                    onTap: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if selectedApps.contains(app) {
                                                selectedApps.remove(app)
                                            } else {
                                                selectedApps.insert(app)
                                            }
                                        }
                                    }
                                )
                                .scaleEffect(animateCards ? 1 : 0.8)
                                .opacity(animateCards ? 1 : 0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(Double(SocialApp.availableApps.firstIndex(of: app) ?? 0) * 0.1),
                                    value: animateCards
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Selection Summary
                        if !selectedApps.isEmpty {
                            VStack(spacing: 12) {
                                Text("Selected Apps (\(selectedApps.count))")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundColor(coral)
                                
                                HStack {
                                    ForEach(Array(selectedApps), id: \.id) { app in
                                        HStack(spacing: 6) {
                                            Image(systemName: app.iconName)
                                                .font(.system(size: 12, weight: .medium))
                                            Text(app.displayName)
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(coral.opacity(0.2))
                                                .stroke(coral.opacity(0.4), lineWidth: 1)
                                        )
                                        .foregroundColor(lightGray)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.3), value: selectedApps)
                            }
                            .padding(.horizontal, 24)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .scrollIndicators(.hidden)
                
                // Bottom CTA Section
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Continue Button
                        Button(action: {
                            if selectedApps.isEmpty {
                                showError(message: "Please select at least one app to continue")
                                return
                            }
                            showingStakeSetup = true
                        }) {
                            ZStack {
                                LinearGradient(
                                    colors: selectedApps.isEmpty ? [.gray.opacity(0.5)] : [orange, coral],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                
                                HStack(spacing: 8) {
                                    Text("Continue to Stake Setup")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .cornerRadius(28)
                            .shadow(
                                color: selectedApps.isEmpty ? .clear : orange.opacity(0.3),
                                radius: 20,
                                x: 0,
                                y: 10
                            )
                        }
                        .disabled(selectedApps.isEmpty)
                        .scaleEffect(selectedApps.isEmpty ? 0.95 : 1)
                        .animation(.easeInOut(duration: 0.2), value: selectedApps.isEmpty)
                        .padding(.horizontal, 24)
                        
                        // Back Button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back to Home")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(peach.opacity(0.8))
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.bottom, 34) // Safe area padding
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateCards = true
            }
        }
        .alert("Selection Required", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showingStakeSetup) {
            StakeSetupView(selectedApps: Array(selectedApps))
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - App Selection Card
struct AppSelectionCard: View {
    let app: SocialApp
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private let lightGray = Color(hex: "f6f6f6")
    private let coral = Color(hex: "f38453")
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onTap()
            }
        }) {
            VStack(spacing: 16) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [coral, coral.opacity(0.8)] : [.white.opacity(0.1), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: app.iconName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(isSelected ? .white : lightGray)
                        .scaleEffect(isSelected ? 1.1 : 1)
                }
                
                // App Name
                Text(app.displayName)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(isSelected ? coral : lightGray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Selection Indicator
                HStack(spacing: 4) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? coral : lightGray.opacity(0.5))
                    
                    Text(isSelected ? "Selected" : "Tap to select")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(isSelected ? coral : lightGray.opacity(0.7))
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.03))
                    .stroke(
                        isSelected ? coral.opacity(0.6) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .shadow(
                        color: isSelected ? coral.opacity(0.2) : .clear,
                        radius: isSelected ? 15 : 0,
                        x: 0,
                        y: isSelected ? 5 : 0
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview
#Preview {
    AppSelectionView()
}