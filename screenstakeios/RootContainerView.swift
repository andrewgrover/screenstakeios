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
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                    
                    Text("Screenstake")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Ready to capture screenshots")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("Home")
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