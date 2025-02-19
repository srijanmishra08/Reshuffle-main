import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseMessaging
import UserNotifications

@main
struct iOSAppApp: App {
    init() {
        FirebaseApp.configure()
        print("Firebase initialized: \(FirebaseApp.app() != nil)")
        requestNotificationPermission()
        Messaging.messaging().delegate = NotificationManager.shared
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
            .onOpenURL { url in
                // Handle Instagram OAuth callback
                if url.scheme == "Reshuffle-IG" && url.host == "auth" {
                    print("Received Instagram OAuth callback: \(url)")
                }
            }
            .accentColor(.black)
        }
    }
    
    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            } else {
                print(granted ? "Notification permission granted." : "Notification permission denied.")
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
        
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }
}
