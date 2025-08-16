//
//  LandingView.swift
//  screenstakeios
//
//  Landing page for ScreenStake app
//

import SwiftUI

struct LandingView: View {
    @State private var isPressed = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 50
    
    // Brand colors from README
    private let blackBg = Color(hex: "000000")
    private let lightGray = Color(hex: "f6f6f6")
    private let peach = Color(hex: "f4bda4")
    private let coral = Color(hex: "f38453")
    private let orange = Color(hex: "f24b02")
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo with glow effect (contains logo + slogan in the PNG)
                ZStack {
                    // Glow backdrop - using the same image with blur
                    Image("brandmark-design-transparent-glow")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320)
                        .blur(radius: 30)
                        .opacity(0.4)
                        .scaleEffect(1.1)
                    
                    // Main logo image (this PNG already contains your logo and slogan)
                    Image("brandmark-design-transparent-glow")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 80)
                
                // Buttons section
                VStack(spacing: 16) {
                    // Primary CTA button with gradient
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed.toggle()
                        }
                        // Handle navigation here
                    }) {
                        ZStack {
                            // Gradient background
                            LinearGradient(
                                colors: [orange, coral],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            
                            HStack(spacing: 8) {
                                Text("Start Staking")
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
                    .offset(y: buttonOffset)
                    .opacity(contentOpacity)
                    
                    // Secondary button with subtle styling
                    Button(action: {
                        // Handle learn more action
                    }) {
                        HStack(spacing: 6) {
                            Text("Learn More")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                            
                            Image(systemName: "info.circle")
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
                    .offset(y: buttonOffset)
                    .opacity(contentOpacity)
                }
                
                Spacer()
                    .frame(height: 60)
            }
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
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LandingView()
}