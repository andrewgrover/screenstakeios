//
//  LandingView.swift
//  screenstakeios
//
//  Landing page for ScreenStake app
//

import SwiftUI

struct LandingView: View {
    @State private var animateIcon = false
    @State private var showGetStarted = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and App Name
                VStack(spacing: 24) {
                    // Animated Icon
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 120, height: 120)
                        
                        // Inner animated ring
                        Circle()
                            .trim(from: 0, to: animateIcon ? 1 : 0.3)
                            .stroke(
                                Color.white,
                                style: StrokeStyle(
                                    lineWidth: 3,
                                    lineCap: .round
                                )
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(animateIcon ? 360 : 0))
                            .animation(
                                .linear(duration: 2)
                                .repeatForever(autoreverses: false),
                                value: animateIcon
                            )
                        
                        // Clock/Timer Icon
                        Image(systemName: "timer")
                            .font(.system(size: 45, weight: .thin))
                            .foregroundColor(.white)
                    }
                    .onAppear {
                        animateIcon = true
                    }
                    
                    // App Name
                    Text("ScreenStake")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .tracking(-1)
                }
                
                Spacer()
                    .frame(height: 60)
                
                // Tagline
                VStack(spacing: 16) {
                    Text("Put Your Money")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Where Your Time Is")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                    .frame(height: 40)
                
                // Value Props
                VStack(spacing: 32) {
                    FeatureRow(
                        icon: "dollarsign.circle",
                        text: "Stake real money on screen time limits"
                    )
                    
                    FeatureRow(
                        icon: "lock.circle",
                        text: "Stay accountable with automatic charges"
                    )
                    
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis.circle",
                        text: "Build better digital habits that stick"
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // CTA Buttons
                VStack(spacing: 16) {
                    // Primary CTA
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showGetStarted = true
                        }
                    }) {
                        HStack {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(28)
                    }
                    .scaleEffect(showGetStarted ? 0.95 : 1.0)
                    
                    // Secondary CTA
                    Button(action: {
                        // Handle learn more
                    }) {
                        Text("Learn More")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .thin))
                .foregroundColor(.white)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// Alternative Minimal Version
struct MinimalLandingView: View {
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Large Typography Focus
                VStack(alignment: .leading, spacing: 8) {
                    Text("SCREEN")
                        .font(.system(size: 56, weight: .black))
                        .foregroundColor(.black)
                    
                    Text("STAKE")
                        .font(.system(size: 56, weight: .black))
                        .foregroundColor(.black)
                    
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 80, height: 4)
                        .padding(.top, 16)
                    
                    Text("Bet on yourself.")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.top, 16)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Simple CTA
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed.toggle()
                    }
                }) {
                    Text("START →")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.black)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .padding(.bottom, 80)
            }
        }
    }
}

#Preview("Dark Theme") {
    LandingView()
}

#Preview("Minimal White") {
    MinimalLandingView()
}