import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

// Function to handle a new connection and trigger a notification
func handleNewConnection(userId: String, addedUser: BusinessCard) {
    // Create a new notification data dictionary
    let notificationData: [String: Any] = [
        "title": "New Connection",
        "subtitle": "\(addedUser.name) added your card.",
        "timestamp": Timestamp(date: Date()),
        "type": "newConnection"
    ]
    
    // Store notification in Firestore
    createNotification(userId: userId, notificationData: notificationData)
    
    // Schedule a local notification
    scheduleLocalNotification(title: "New Connection", subtitle: "\(addedUser.name) added your card.")
}

// Function to suggest a new connection based on profession or proximity
func suggestConnection(for user: BusinessCard) {
    let db = Firestore.firestore()
    
    // Query Firestore to find users with the same profession
    db.collection("users").whereField("profession", isEqualTo: user.profession).getDocuments { (snapshot, error) in
        if let error = error {
            print("Error fetching suggested connections: \(error)")
            return
        }
        
        guard let documents = snapshot?.documents else { return }
        
        // Iterate through users with similar profession and send notifications
        for doc in documents {
            let suggestedUser = doc.data()
            let suggestedUserName = suggestedUser["name"] as? String ?? ""
            let suggestedUserProfession = suggestedUser["profession"] as? String ?? ""
            
            // Create notification data
            let notificationData: [String: Any] = [
                "title": "Suggested Connection",
                "subtitle": "You might know \(suggestedUserName), \(suggestedUserProfession)",
                "timestamp": Timestamp(date: Date()),
                "type": "suggestedConnection"
            ]
            
            // Store notification in Firestore
            createNotification(userId: user.id.uuidString, notificationData: notificationData)
            
            // Schedule local notification
            scheduleLocalNotification(title: "Suggested Connection", subtitle: "You might know \(suggestedUserName), \(suggestedUserProfession)")
        }
    }
}

// Function to notify a user about a new message
func notifyNewMessage(from sender: BusinessCard, to recipientId: String, message: String) {
    // Create notification data
    let notificationData: [String: Any] = [
        "title": "New Message",
        "subtitle": "\(sender.name) sent you a message: \(message)",
        "timestamp": Timestamp(date: Date()),
        "type": "newMessage"
    ]
    
    // Store notification in Firestore
    createNotification(userId: recipientId, notificationData: notificationData)
    
    // Schedule local notification
    scheduleLocalNotification(title: "New Message", subtitle: "\(sender.name) sent you a message: \(message)")
}

// Function to create a new notification document in Firestore
func createNotification(userId: String, notificationData: [String: Any]) {
    let db = Firestore.firestore()
    
    // Create a new collection "notifications" for the user if it doesn't exist
    db.collection("users").document(userId).collection("notifications").addDocument(data: notificationData) { error in
        if let error = error {
            print("Error adding notification: \(error)")
        } else {
            print("Notification added successfully.")
        }
    }
}

// Function to schedule a local notification
func scheduleLocalNotification(title: String, subtitle: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = subtitle
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling local notification: \(error)")
        }
    }
}

struct NotificationsView: View {
    @State private var notifications: [FirestoreNotificationItem] = []
    @State private var isNavigationActive: Bool = false
    @State private var userId: String? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(notifications) { notification in
                    NotificationCard(title: notification.title, subtitle: notification.subtitle, timestamp: notification.timestamp)
                        .listRowInsets(EdgeInsets())
                        .overlay(Divider().background(Color.white), alignment: .bottom)
                }
                .onDelete(perform: deleteNotification)
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
