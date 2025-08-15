//
//  AppCoordinator.swift
//  screenstakeios
//
//  Centralized navigation and app flow management
//

import SwiftUI

// MARK: - Navigation Destinations
enum AppDestination: Hashable {
    case home
    case screenshotDetail(id: String)
    case settings
    case onboarding
}

// MARK: - App Coordinator
@MainActor
class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var isFirstLaunch: Bool
    @Published var currentTab: TabSelection = .home
    
    enum TabSelection: Int {
        case home = 0
        case library = 1
        case settings = 2
    }
    
    init() {
        // Check if this is the first launch
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Navigation Methods
    func navigate(to destination: AppDestination) {
        path.append(destination)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isFirstLaunch = false
    }
    
    // MARK: - Tab Management
    func switchTab(to tab: TabSelection) {
        currentTab = tab
    }
}

// MARK: - View Extension for Navigation
extension View {
    func withAppNavigation() -> some View {
        self.navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .home:
                // HomeView() // Uncomment when created
                Text("Home View")
            case .screenshotDetail(let id):
                Text("Screenshot Detail: \(id)")
            case .settings:
                Text("Settings View")
            case .onboarding:
                Text("Onboarding View")
            }
        }
    }
}