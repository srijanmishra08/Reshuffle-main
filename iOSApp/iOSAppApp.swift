//
//  iOSAppApp.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 12/12/23.
import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseMessaging
import UserNotifications

@main
struct iOSAppApp: App {
    init() {
        FirebaseApp.configure()
        requestNotificationPermission() // Request notification permission
        Messaging.messaging().delegate = NotificationManager.shared as? any MessagingDelegate // Set FCM delegate
    }
    
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var navigateToFirstPage = false
    let userData = UserData()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                if isLoggedIn {
                    FirstPage()
                        .navigationBarBackButtonHidden(true)
                } else {
                    ContentView()
                        .environmentObject(userData)
                        .accentColor(.black)
                }
            }
            .onAppear {
                if isLoggedIn {
                    navigateToFirstPage = true
                }
            }
            .accentColor(.black)
        }
//        .onOpenURL { url in
//            // Handle push notification action on URL
//            print("Received URL: \(url)")
//        }
    }
    
    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            } else {
                print(granted ? "Notification permission granted." : "Notification permission denied.")
            }
        }
        
        UNUserNotificationCenter.current().delegate = NotificationManager.shared as? any UNUserNotificationCenterDelegate
    }
}
