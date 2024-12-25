import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let db = Firestore.firestore()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Create a notification when a connection is made
    func createConnectionNotification(connectedUser: BusinessCard) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("Error: Current user is not logged in")
            return
        }
        
        // Notification data structure
        let notificationData: [String: Any] = [
            "title": "New Connection",
            "subtitle": "You've connected with \(connectedUser.name)",
            "timestamp": FieldValue.serverTimestamp(),
            "type": "connection",
            "userId": connectedUser.id.uuidString,
            "read": false
        ]
        
        // Create notification in Firestore
        db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .addDocument(data: notificationData) { error in
                if let error = error {
                    print("Failed to create notification: \(error.localizedDescription)")
                } else {
                    print("Notification created successfully")
                    self.sendLocalNotification(
                        title: "New Connection",
                        body: "You've connected with \(connectedUser.name)"
                    )
                }
            }
    }
    
    // Send local notification
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending local notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetch notifications for the current user
    func fetchNotifications(completion: @escaping ([FirestoreNotificationItem]) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            completion([])
            return
        }
        
        db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .order(by: "timestamp", descending: true)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let notifications = querySnapshot?.documents.compactMap { document -> FirestoreNotificationItem? in
                    let data = document.data()
                    return FirestoreNotificationItem(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        subtitle: data["subtitle"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        type: data["type"] as? String ?? "",
                        read: data["read"] as? Bool ?? false
                    )
                } ?? []
                
                completion(notifications)
            }
    }
    
    // Create notification for team announcements
    func createTeamAnnouncement(title: String, message: String) {
        db.collection("UserDatabase").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users for announcement: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No users found for team announcement.")
                return
            }
            
            documents.forEach { document in
                let userId = document.documentID
                
                let announcementData: [String: Any] = [
                    "title": "📢 \(title)",
                    "subtitle": message,
                    "timestamp": FieldValue.serverTimestamp(),
                    "type": "team_announcement",
                    "read": false
                ]
                
                self.db.collection("Notifications")
                    .document(userId)
                    .collection("UserNotifications")
                    .addDocument(data: announcementData) { error in
                        if let error = error {
                            print("Failed to create team announcement: \(error.localizedDescription)")
                        }
                    }
            }
        }
    }
}

// Data model for notifications
struct FirestoreNotificationItem: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var timestamp: Date
    var type: String
    var read: Bool = false
}
