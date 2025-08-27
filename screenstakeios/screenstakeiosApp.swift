//
//  screenstakeiosApp.swift
//  screenstakeios
//
//  Created by Andrew Grover on 8/14/25.
//

import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured")
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        // Initialize monitoring service
        Task {
            _ = await StakeMonitoringService.shared
        }
        
        return true
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound, .criticalAlert] // Kept criticalAlert from original
        ) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
                self.setupNotificationCategories()
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Charge notification category with actions (restored from original)
        let disputeAction = UNNotificationAction(
            identifier: "DISPUTE_ACTION",
            title: "Dispute Charge",
            options: [.foreground]
        )
        
        let viewReceiptAction = UNNotificationAction(
            identifier: "VIEW_RECEIPT_ACTION",
            title: "View Receipt",
            options: []
        )
        
        let chargeCategory = UNNotificationCategory(
            identifier: "CHARGE_NOTIFICATION",
            actions: [disputeAction, viewReceiptAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Authentication required category (restored from original)
        let authenticateAction = UNNotificationAction(
            identifier: "AUTHENTICATE_ACTION",
            title: "Complete Authentication",
            options: [.foreground, .authenticationRequired]
        )
        
        let authCategory = UNNotificationCategory(
            identifier: "AUTH_REQUIRED",
            actions: [authenticateAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            chargeCategory,
            authCategory
        ])
    }
    
    // Handle remote notifications
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Send device token to your backend
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Device Token: \(token)")
        
        // Store token for backend
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // Handle notification responses (restored from original)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "DISPUTE_ACTION":
            if let chargeId = userInfo["chargeId"] as? String {
                handleDisputeAction(chargeId: chargeId)
            }
            
        case "VIEW_RECEIPT_ACTION":
            if let chargeId = userInfo["chargeId"] as? String {
                handleViewReceiptAction(chargeId: chargeId)
            }
            
        case "AUTHENTICATE_ACTION":
            if let stakeId = userInfo["stakeId"] as? String {
                handleAuthenticationAction(stakeId: stakeId)
            }
            
        default:
            break
        }
        
        completionHandler()
    }
    
    // Notification action handlers (restored from original)
    private func handleDisputeAction(chargeId: String) {
        // Navigate to dispute view
        NotificationCenter.default.post(
            name: Notification.Name("ShowDisputeView"),
            object: nil,
            userInfo: ["chargeId": chargeId]
        )
    }
    
    private func handleViewReceiptAction(chargeId: String) {
        // Open receipt URL
        NotificationCenter.default.post(
            name: Notification.Name("ShowReceipt"),
            object: nil,
            userInfo: ["chargeId": chargeId]
        )
    }
    
    private func handleAuthenticationAction(stakeId: String) {
        // Open 3DS authentication flow
        NotificationCenter.default.post(
            name: Notification.Name("Show3DSAuthentication"),
            object: nil,
            userInfo: ["stakeId": stakeId]
        )
    }
}

@main
struct screenstakeiosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var paymentManager = StripePaymentManager.shared
    @StateObject private var monitoringService = StakeMonitoringService.shared
    
    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(paymentManager)
                .environmentObject(monitoringService)
                .onOpenURL { url in
                    // Handle Stripe return URLs for 3DS (restored from original)
                    if url.scheme == "screenstake" {
                        handleStripeReturnURL(url)
                    }
                }
        }
    }
    
    // Stripe URL handler (restored from original)
    private func handleStripeReturnURL(_ url: URL) {
        // Handle Stripe payment confirmation returns
        if url.host == "stripe-redirect" {
            // Process the payment confirmation
            NotificationCenter.default.post(
                name: Notification.Name("StripePaymentReturn"),
                object: nil,
                userInfo: ["url": url]
            )
        }
    }
}