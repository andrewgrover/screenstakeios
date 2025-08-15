//
//  LandingView.swift
//  screenstakeios
//
//  Landing page for ScreenStake app
//

import SwiftUI

struct LandingView: View {
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 60, weight: .thin))
                        .foregroundColor(.white)

                    Text("ScreenStake")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Stake cash on your screen-time limit.\nGo over and pay the price.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed.toggle()
                    }
                }) {
                    Text("Start Staking")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(30)
                        .scaleEffect(isPressed ? 0.95 : 1)
                }
                .padding(.horizontal, 32)

                Button(action: {
                    // Handle learn more action
                }) {
                    Text("Learn More")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    LandingView()
}
