//
//  LandingView.swift
//  screenstakeios
//
//  Updated Landing page with navigation to app selection
//

import SwiftUI

struct LandingView: View {
    @State private var isPressed = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 50
    @State private var featuresOpacity: Double = 0
    @State private var showingAppSelection = false
    
    // Brand colors from README
    private let blackBg = Color.black
    private let lightGray = Color(red: 0.965, green: 0.965, blue: 0.965) // #f6f6f6
    private let peach = Color(red: 0.957, green: 0.741, blue: 0.643) // #f4bda4
    private let coral = Color(red: 0.953, green: 0.518, blue: 0.325) // #f38453
    private let orange = Color(red: 0.949, green: 0.294, blue: 0.008) // #f24b02
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black background
                blackBg
                    .ignoresSafeArea()
                
                // Subtle gradient overlay for depth
                LinearGradient(
                    colors: [
                        blackBg,
                        orange.opacity(0.03),
                        blackBg
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .blendMode(.screen)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacing
                        Spacer()
                            .frame(height: 80)
                        
                        // Logo section with fallback
                        VStack(spacing: 20) {
                            ZStack {
                                // Fallback logo using SF Symbols
                                VStack(spacing: 12) {
                                    Image(systemName: "target")
                                        .font(.system(size: 80, weight: .ultraLight))
                                        .foregroundColor(coral)
                                    
                                    Text("Screenstake")
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundColor(lightGray)
                                }
                            }
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                            .frame(height: 60)
                        
                        // Trust indicators
                        VStack(spacing: 24) {
                            // Security badge
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(coral)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bank-level Security")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(lightGray)
                                    
                                    Text("Your payments are protected")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(lightGray.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .stroke(coral.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Features grid
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    FeatureItem(
                                        icon: "target",
                                        title: "Set Goals",
                                        description: "Daily screen time limits"
                                    )
                                    
                                    FeatureItem(
                                        icon: "dollarsign.circle",
                                        title: "Stake Money",
                                        description: "Put skin in the game"
                                    )
                                }
                                
                                HStack(spacing: 20) {
                                    FeatureItem(
                                        icon: "chart.line.uptrend.xyaxis",
                                        title: "Track Progress",
                                        description: "Monitor your success"
                                    )
                                    
                                    FeatureItem(
                                        icon: "trophy",
                                        title: "Win Rewards",
                                        description: "Keep your money + earn"
                                    )
                                }
                            }
                            .opacity(featuresOpacity)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                            .frame(height: 50)
                        
                        // CTA Section
                        VStack(spacing: 16) {
                            // Primary CTA button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isPressed.toggle()
                                }
                                
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // Navigate to app selection
                                showingAppSelection = true
                            }) {
                                ZStack {
                                    // Gradient background
                                    LinearGradient(
                                        colors: [orange, coral],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    
                                    HStack(spacing: 8) {
                                        Text("Start Your First Stake")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .cornerRadius(28)
                                .shadow(color: orange.opacity(0.3), radius: 20, x: 0, y: 10)
                                .scaleEffect(isPressed ? 0.95 : 1)
                            }
                            .padding(.horizontal, 40)
                            
                            // Secondary button
                            Button(action: {
                                // Handle learn more action - could show an info sheet
                                // For now, just haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                HStack(spacing: 6) {
                                    Text("How It Works")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                    
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(peach.opacity(0.8))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(
                                    Capsule()
                                        .stroke(peach.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .offset(y: buttonOffset)
                        .opacity(contentOpacity)
                        
                        Spacer()
                            .frame(height: 80)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .preferredColorScheme(.dark)
            .onAppear {
                // Staggered animations on appear
                withAnimation(.easeOut(duration: 0.8)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    contentOpacity = 1.0
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
                    buttonOffset = 0
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
                    featuresOpacity = 1.0
                }
            }
            .fullScreenCover(isPresented: $showingAppSelection) {
                AppSelectionView()
            }
        }
        .navigationBarHidden(true)
    }
}

// Feature item component for trust building
struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    private let lightGray = Color(red: 0.965, green: 0.965, blue: 0.965) // #f6f6f6
    private let coral = Color(red: 0.953, green: 0.518, blue: 0.325) // #f38453
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(coral)
                .frame(height: 32)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(lightGray)
            
            Text(description)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(lightGray.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    LandingView()
}