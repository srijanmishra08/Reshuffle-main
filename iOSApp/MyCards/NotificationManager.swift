import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

// MARK: - NotificationError Enum
enum NotificationError: Error {
    case userNotAuthenticated
    case firestoreError(String)
    case permissionDenied
    case invalidData
    case networkError
}

// MARK: - NotificationType Enum
enum NotificationType: String {
    case connection = "connection"
    case suggestion = "suggestion"
    case proximity = "proximity"
    case teamAnnouncement = "team_announcement"
    case event = "event"
}

// MARK: - NotificationManager Class
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    // MARK: - Properties
    static let shared = NotificationManager()
    
    private let db = Firestore.firestore()
    private var notificationTokenHandle: ListenerRegistration?
    
    // MARK: - Initialization
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationHandling()
    }
    
    deinit {
        notificationTokenHandle?.remove()
    }
    
    // MARK: - Setup Methods
    private func setupNotificationHandling() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Handling
    func requestNotificationPermissions() async throws -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            throw NotificationError.permissionDenied
        }
    }
    
    // MARK: - Notification Creation Methods
    func createConnectionNotification(connectedUser: BusinessCard) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        let notificationData: [String: Any] = [
            "title": "New Connection",
            "subtitle": "You've connected with \(connectedUser.name)",
            "timestamp": FieldValue.serverTimestamp(),
            "type": NotificationType.connection.rawValue,
            "userId": connectedUser.id.uuidString,
            "read": false,
            "metadata": [
                "connectedUserId": connectedUser.id.uuidString,
                "connectedUserName": connectedUser.name
            ]
        ]
        
        try await createNotification(userId: currentUserId, data: notificationData)
        await sendLocalNotification(title: "New Connection", body: "You've connected with \(connectedUser.name)")
    }
    
    func createSuggestedConnectionNotification(suggestedUser: BusinessCard) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        let notificationData: [String: Any] = [
            "title": "Suggested Connection",
            "subtitle": "You might want to connect with \(suggestedUser.name)",
            "timestamp": FieldValue.serverTimestamp(),
            "type": NotificationType.suggestion.rawValue,
            "userId": suggestedUser.id.uuidString,
            "read": false,
            "metadata": [
                "suggestedUserId": suggestedUser.id.uuidString,
                "suggestedUserName": suggestedUser.name
            ]
        ]
        
        try await createNotification(userId: currentUserId, data: notificationData)
    }
    
    func createProximityNotification(nearbyUser: BusinessCard) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        let notificationData: [String: Any] = [
            "title": "Nearby Professional",
            "subtitle": "Someone in your field is nearby: \(nearbyUser.name)",
            "timestamp": FieldValue.serverTimestamp(),
            "type": NotificationType.proximity.rawValue,
            "userId": nearbyUser.id.uuidString,
            "read": false,
            "metadata": [
                "nearbyUserId": nearbyUser.id.uuidString,
                "nearbyUserName": nearbyUser.name,
                "profession": nearbyUser.profession ?? "Professional"
            ]
        ]
        
        try await createNotification(userId: currentUserId, data: notificationData)
    }
    
    func createTeamAnnouncement(title: String, message: String) async throws {
        let snapshot = try await db.collection("UserDatabase").getDocuments()
        
        for document in snapshot.documents {
            let userId = document.documentID
            
            let announcementData: [String: Any] = [
                "title": "📢 \(title)",
                "subtitle": message,
                "timestamp": FieldValue.serverTimestamp(),
                "type": NotificationType.teamAnnouncement.rawValue,
                "read": false,
                "metadata": [
                    "announcementId": UUID().uuidString,
                    "priority": "normal"
                ]
            ]
            
            try await createNotification(userId: userId, data: announcementData)
        }
    }
    
    // MARK: - Helper Methods
    private func createNotification(userId: String, data: [String: Any]) async throws {
        guard !userId.isEmpty else {
            throw NotificationError.invalidData
        }
        
        // Validate data
        guard !data.isEmpty else {
            throw NotificationError.invalidData
        }
        
        do {
            print("Attempting to write to Firestore with data: \(data)")
            try await db.collection("Notifications")
                .document(userId)
                .collection("UserNotifications")
                .addDocument(data: data)
            
            print("Firestore write operation succeeded")
            await updateBadgeCount()
        } catch {
            print("Firestore write operation failed: \(error.localizedDescription)")
            throw NotificationError.firestoreError(error.localizedDescription)
        }
    }
    
    private func sendLocalNotification(title: String, body: String) async {
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
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error sending local notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Methods
    func fetchNotifications() async throws -> [FirestoreNotificationItem] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        let snapshot = try await db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> FirestoreNotificationItem? in
            let data = document.data()
            return FirestoreNotificationItem(
                id: document.documentID,
                title: data["title"] as? String ?? "",
                subtitle: data["subtitle"] as? String ?? "",
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                type: data["type"] as? String ?? "",
                read: data["read"] as? Bool ?? false,
                metadata: data["metadata"] as? [String: Any] ?? [:]
            )
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() async {
        do {
            let notifications = try await fetchNotifications()
            let unreadCount = notifications.filter { !$0.read }.count
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = unreadCount
            }
        } catch {
            print("Error updating badge count: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification Management
    func markAsRead(notificationId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        try await db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .document(notificationId)
            .updateData(["read": true])
        
        await updateBadgeCount()
    }
    
    func deleteNotification(notificationId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        try await db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .document(notificationId)
            .delete()
        
        await updateBadgeCount()
    }
    
    func clearAllNotifications() async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        let snapshot = try await db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
        
        await updateBadgeCount()
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        // Add your custom handling here based on userInfo
        completionHandler()
    }
}

// MARK: - Data Models
struct FirestoreNotificationItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let timestamp: Date
    let type: String
    var read: Bool
    let metadata: [String: Any]
}
import FirebaseMessaging

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // Send the token to your server if needed
    }
}
