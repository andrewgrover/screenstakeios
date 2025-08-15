//
//  RootContainerView.swift
//  screenstakeios
//

import SwiftUI

struct RootContainerView: View {
    var body: some View {
        // For now, just show a simple tab view
        TabView {
            // Home Tab
            NavigationStack {
                ZStack {
                    // Futuristic gradient background
                    LinearGradient(
                        colors: [.black, .purple.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 24) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 72, weight: .thin))
                            .foregroundStyle(.white)

                        Text("Screenstake")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        Text("Capture the future")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Library Tab
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Screenshot Library")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        Text("Your screenshots will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Library")
            }
            .tabItem {
                Label("Library", systemImage: "photo.stack")
            }
            
            // Settings Tab
            NavigationStack {
                List {
                    Section("General") {
                        Label("Storage", systemImage: "internaldrive")
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    RootContainerView()
}