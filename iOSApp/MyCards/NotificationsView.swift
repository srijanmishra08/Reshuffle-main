import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

struct NotificationsView: View {
    @State private var notifications: [FirestoreNotificationItem] = []
    @State private var isNavigationActive: Bool = false
    @State private var userId: String? = nil
    
    // Sample data to display when no notifications are available
    let sampleData: [FirestoreNotificationItem] = [
        FirestoreNotificationItem(id: "1", title: "Welcome to the App!", subtitle: "This is a sample notification.", timestamp: Date(), type: "sample"),
        FirestoreNotificationItem(id: "2", title: "New Features", subtitle: "Check out the latest features of our app.", timestamp: Date(), type: "sample"),
        FirestoreNotificationItem(id: "3", title: "Stay Connected", subtitle: "Invite friends and build your network.", timestamp: Date(), type: "sample")
    ]
    
    var body: some View {
        NavigationView {
            List {
                if notifications.isEmpty {
                    // Show sample data when notifications array is empty
                    ForEach(sampleData) { notification in
                        NotificationCard(title: notification.title, subtitle: notification.subtitle, timestamp: notification.timestamp)
                            .listRowInsets(EdgeInsets())
                            .overlay(Divider().background(Color.white), alignment: .bottom)
                    }
                } else {
                    // Show real notifications
                    ForEach(notifications) { notification in
                        NotificationCard(title: notification.title, subtitle: notification.subtitle, timestamp: notification.timestamp)
                            .listRowInsets(EdgeInsets())
                            .overlay(Divider().background(Color.white), alignment: .bottom)
                    }
                    .onDelete(perform: deleteNotification)
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Notifications")
            .navigationBarItems(leading: backButton)
            .background(
                NavigationLink(destination: MyCards().navigationBarBackButtonHidden(true), isActive: $isNavigationActive) {
                    EmptyView()
                }
            )
        }
        .onAppear {
            requestNotificationPermission()
            fetchCurrentUser()
        }
    }

    // Fetch current authenticated user from Firebase Auth
    func fetchCurrentUser() {
        if let user = Auth.auth().currentUser {
            self.userId = user.uid
            fetchNotifications(for: user.uid)
            setupNotificationListener(for: user.uid)
        } else {
            print("User not logged in.")
        }
    }

    var backButton: some View {
        Button(action: {
            isNavigationActive = true
        }) {
            Image(systemName: "arrow.left")
                .foregroundColor(Color.primary)
        }
    }

    // Delete notification from Firestore
    func deleteNotification(at offsets: IndexSet) {
        guard let userId = userId else { return }
        let db = Firestore.firestore()
        offsets.forEach { index in
            let notificationId = notifications[index].id
            db.collection("users").document(userId).collection("notifications").document(notificationId).delete { error in
                if let error = error {
                    print("Error deleting notification: \(error)")
                }
            }
        }
        notifications.remove(atOffsets: offsets)
    }

    // Request permission for local notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            } else {
                print(granted ? "Notification permission granted." : "Notification permission denied.")
            }
        }
    }

    // Fetch notifications from Firebase
    func fetchNotifications(for userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("notifications").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching notifications: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            self.notifications = documents.compactMap { doc in
                let data = doc.data()
                let title = data["title"] as? String ?? ""
                let subtitle = data["subtitle"] as? String ?? ""
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let type = data["type"] as? String ?? ""
                
                return FirestoreNotificationItem(id: doc.documentID, title: title, subtitle: subtitle, timestamp: timestamp, type: type)
            }
        }
    }

    // Set up real-time listener for Firebase updates
    func setupNotificationListener(for userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("notifications").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening for notifications: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            self.notifications = documents.compactMap { doc in
                let data = doc.data()
                let title = data["title"] as? String ?? ""
                let subtitle = data["subtitle"] as? String ?? ""
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let type = data["type"] as? String ?? ""
                
                return FirestoreNotificationItem(id: doc.documentID, title: title, subtitle: subtitle, timestamp: timestamp, type: type)
            }
        }
    }
}

struct NotificationCard: View {
    var title: String
    var subtitle: String
    var timestamp: Date

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            .padding()
            
            Spacer()
            
            Text(timeFormatted(timestamp))
                .font(.caption)
                .foregroundColor(.black)
                .padding()
        }
        .background(Color.white)
        .cornerRadius(0)
        .foregroundColor(.black)
        .padding(.vertical, 0)
    }
    
    func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Data model for notifications
struct FirestoreNotificationItem: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var timestamp: Date
    var type: String
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
