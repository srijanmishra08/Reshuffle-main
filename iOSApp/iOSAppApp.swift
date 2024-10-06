//
//  iOSAppApp.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 12/12/23.

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct iOSAppApp: App {
    init() {
        FirebaseApp.configure()
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
                }
                else {
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
        
    }
    
}
