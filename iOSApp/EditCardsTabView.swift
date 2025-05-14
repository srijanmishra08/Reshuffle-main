import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UserNotifications
import MapKit

struct EditCardsTabView: View {
    @EnvironmentObject var userDataViewModel: UserDataViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSignOutAlert = false
    @State private var isSigningOut = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Edit Cards")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Edit cards content
                        EditCardsContent()
                            .environmentObject(userDataViewModel)
                        
                        // Sign Out button
                        Button(action: {
                            showingSignOutAlert = true
                        }) {
                            HStack {
                                Spacer()
                                if isSigningOut {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding(.trailing, 10)
                                }
                                Text("Sign Out")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .disabled(isSigningOut)
                        .padding(.vertical, 20)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        performSignOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func performSignOut() {
        isSigningOut = true
        
        // First, remove FCM token to stop receiving notifications
        guard let userID = Auth.auth().currentUser?.uid else {
            // No user ID, just sign out
            completeSignOut()
            return
        }
        
        // Delete FCM token from Firestore
        Firestore.firestore().collection("users").document(userID).updateData([
            "fcmToken": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("Error removing FCM token: \(error.localizedDescription)")
            }
            // Continue with sign out process regardless
            completeSignOut()
        }
    }
    
    private func completeSignOut() {
        do {
            try Auth.auth().signOut()
            
            // Reset local state
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "FCMToken")
            UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
            UserDefaults.standard.synchronize()
            
            // Clear all pending notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            // Reset app state to force login screen
            DispatchQueue.main.async {
                // This will trigger the app to show the login screen
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                UserDefaults.standard.synchronize()
                
                // Set login state in AppStorage
                withAnimation {
                    userDataViewModel.isLoggedIn = false
                }
                
                isSigningOut = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            isSigningOut = false
            
            // Show error alert
            let alert = UIAlertController(
                title: "Sign Out Failed",
                message: "An error occurred while signing out: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
}

// A component that displays edit cards content using the current implementation
struct EditCardsContent: View {
    @EnvironmentObject var userDataViewModel: UserDataViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Reuse the card editing content from EditCards
            
            // Twitter Connect Card
            TwitterConnectCard()
            
            // Add spacing between cards
            Divider()
                .padding(.horizontal)
            
            // Display any existing cards to edit
            ForEach(userDataViewModel.userBusinessCards ?? [], id: \.id) { card in
                BusinessCardEditItem(card: card)
            }
            
            // Show message if no cards exist
            if userDataViewModel.userBusinessCards?.isEmpty ?? true {
                Text("No business cards to edit")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.horizontal)
        .onAppear {
            // Load user's cards when view appears
            userDataViewModel.fetchUserCards()
        }
    }
}

// Twitter Connect Card - simplified without LinkedIn and Instagram
struct TwitterConnectCard: View {
    @State private var isConnected = false
    @State private var twitterHandle = ""
    @State private var showTwitterAuthSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect Social Account")
                .font(.headline)
                .padding(.top, 8)
            
            HStack {
                Image("twitter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                
                if isConnected {
                    Text("@\(twitterHandle)")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        disconnectTwitter()
                    }) {
                        Text("Disconnect")
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Twitter")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        connectTwitter()
                    }) {
                        Text("Connect")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Twitter handle entry field
            if !isConnected {
                TextField("Enter Twitter handle (e.g. johndoe)", text: $twitterHandle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    
                Button(action: {
                    saveTwitterHandle()
                }) {
                    Text("Save Twitter Handle")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(twitterHandle.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(twitterHandle.isEmpty)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            // Check if user has already connected Twitter
            checkTwitterConnection()
        }
    }
    
    private func checkTwitterConnection() {
        if let handle = UserDefaults.standard.string(forKey: "TwitterHandle"), !handle.isEmpty {
            twitterHandle = handle
            isConnected = true
        }
    }
    
    private func connectTwitter() {
        if !twitterHandle.isEmpty {
            saveTwitterHandle()
        } else {
            showTwitterAuthSheet = true
        }
    }
    
    private func saveTwitterHandle() {
        // Simple handle saving implementation
        if !twitterHandle.isEmpty {
            // Remove @ if user entered it
            if twitterHandle.hasPrefix("@") {
                twitterHandle = String(twitterHandle.dropFirst())
            }
            
            // Save the handle to UserDefaults
            UserDefaults.standard.set(twitterHandle, forKey: "TwitterHandle")
            UserDefaults.standard.synchronize()
            
            // Update the connection status
            isConnected = true
        }
    }
    
    private func disconnectTwitter() {
        // Clear the Twitter handle
        twitterHandle = ""
        UserDefaults.standard.removeObject(forKey: "TwitterHandle")
        UserDefaults.standard.synchronize()
        
        // Update the connection status
        isConnected = false
    }
}

// A simplified business card item for editing
struct BusinessCardEditItem: View {
    let card: BusinessCard
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.headline)
                    
                    if !card.company.isEmpty {
                        Text(card.company)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !card.role.isEmpty {
                        Text(card.role)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Edit button
                NavigationLink(destination: EditCardDetailView(card: card)) {
                    Image(systemName: "pencil")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

// Placeholder for the detailed edit view
struct EditCardDetailView: View {
    let card: BusinessCard
    
    var body: some View {
        Text("Edit \(card.name)'s Card")
            .navigationTitle("Edit Card")
    }
}

// Preview
struct EditCardsTabView_Previews: PreviewProvider {
    static var previews: some View {
        EditCardsTabView()
            .environmentObject(UserDataViewModel())
    }
} 