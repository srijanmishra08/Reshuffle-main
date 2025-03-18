import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import FirebaseMessaging

// MARK: - NotificationError Enum
enum NotificationError: Error {
    case userNotAuthenticated
    case firestoreError(String)
    case permissionDenied
    case invalidData
    case networkError
    case retryFailed
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
    
    // Retry configuration
    private let maxRetryCount = 3
    private let retryDelayBase: UInt64 = 1_000_000_000 // 1 second in nanoseconds
    
    // MARK: - Initialization
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationHandling()
        registerNotificationCategories()
    }
    
    deinit {
        notificationTokenHandle?.remove()
    }
    
    // MARK: - Setup Methods
    private func setupNotificationHandling() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func registerForRemoteNotifications() {
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        UIApplication.shared.registerForRemoteNotifications()
        
        // Save FCM token to Firestore when received
        if let token = Messaging.messaging().fcmToken {
            saveTokenToFirestore(token: token)
        }
    }
    
    private func registerNotificationCategories() {
        // Define connection request category
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_CONNECTION",
            title: "Accept",
            options: .foreground
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_CONNECTION",
            title: "Decline",
            options: .destructive
        )
        
        let connectionCategory = UNNotificationCategory(
            identifier: "CONNECTION_REQUEST",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Define suggestion category
        let viewSuggestionAction = UNNotificationAction(
            identifier: "VIEW_SUGGESTION",
            title: "View Profile",
            options: .foreground
        )
        
        let dismissSuggestionAction = UNNotificationAction(
            identifier: "DISMISS_SUGGESTION",
            title: "Dismiss",
            options: .destructive
        )
        
        let suggestionCategory = UNNotificationCategory(
            identifier: "SUGGESTION_REQUEST",
            actions: [viewSuggestionAction, dismissSuggestionAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            connectionCategory,
            suggestionCategory
        ])
    }
    
    private func saveTokenToFirestore(token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let tokenData: [String: Any] = [
            "token": token,
            "updatedAt": FieldValue.serverTimestamp(),
            "device": UIDevice.current.model,
            "osVersion": UIDevice.current.systemVersion
        ]
        
        db.collection("Users")
            .document(userId)
            .collection("Tokens")
            .document(token)
            .setData(tokenData) { error in
                if let error = error {
                    print("Error saving token: \(error.localizedDescription)")
                } else {
                    print("FCM token saved to Firestore successfully")
                }
            }
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
        
        try await createNotificationWithRetry(userId: currentUserId, data: notificationData)
        
        // Create local notification with category for interactivity
        let content = UNMutableNotificationContent()
        content.title = "New Connection"
        content.body = "You've connected with \(connectedUser.name)"
        content.sound = .default
        content.categoryIdentifier = "CONNECTION_REQUEST"
        content.userInfo = [
            "connectedUserId": connectedUser.id.uuidString,
            "connectedUserName": connectedUser.name,
            "type": NotificationType.connection.rawValue
        ]
        
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
        
        try await createNotificationWithRetry(userId: currentUserId, data: notificationData)
        
        // Create local notification with suggestion category
        let content = UNMutableNotificationContent()
        content.title = "Suggested Connection"
        content.body = "You might want to connect with \(suggestedUser.name)"
        content.sound = .default
        content.categoryIdentifier = "SUGGESTION_REQUEST"
        content.userInfo = [
            "suggestedUserId": suggestedUser.id.uuidString,
            "suggestedUserName": suggestedUser.name,
            "type": NotificationType.suggestion.rawValue
        ]
        
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
        
        try await createNotificationWithRetry(userId: currentUserId, data: notificationData)
        
        // Send local notification
        await sendLocalNotification(
            title: "Nearby Professional",
            body: "Someone in your field is nearby: \(nearbyUser.name)",
            userInfo: [
                "nearbyUserId": nearbyUser.id.uuidString,
                "nearbyUserName": nearbyUser.name,
                "type": NotificationType.proximity.rawValue
            ]
        )
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
            
            try await createNotificationWithRetry(userId: userId, data: announcementData)
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
    
    private func createNotificationWithRetry(userId: String, data: [String: Any], retryCount: Int = 0) async throws {
        if retryCount >= maxRetryCount {
            throw NotificationError.retryFailed
        }
        
        do {
            try await createNotification(userId: userId, data: data)
        } catch let error as NotificationError {
            if case .firestoreError = error {
                // Only retry network errors
                print("Network error occurred, retrying (\(retryCount + 1)/\(maxRetryCount))...")
                
                // Exponential backoff
                let delay = retryDelayBase * UInt64(pow(2.0, Double(retryCount)))
                try await Task.sleep(nanoseconds: delay)
                
                // Recursive retry with incremented count
                try await createNotificationWithRetry(userId: userId, data: data, retryCount: retryCount + 1)
            } else {
                throw error
            }
        }
    }
    
    private func createNotificationFromRemote(title: String, body: String, type: NotificationType, metadata: [AnyHashable: Any]) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        // Convert AnyHashable dictionary to regular String:Any dictionary
        var metadataDict: [String: Any] = [:]
        for (key, value) in metadata {
            if let keyString = key as? String {
                metadataDict[keyString] = value
            }
        }
        
        let notificationData: [String: Any] = [
            "title": title,
            "subtitle": body,
            "timestamp": FieldValue.serverTimestamp(),
            "type": type.rawValue,
            "read": false,
            "metadata": metadataDict
        ]
        
        try await createNotificationWithRetry(userId: currentUserId, data: notificationData)
    }
    
    private func sendLocalNotification(title: String, body: String, userInfo: [String: Any] = [:]) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Add any additional user info
        for (key, value) in userInfo {
            content.userInfo[key] = value
        }
        
        // Set category identifier if available
        if let type = userInfo["type"] as? String {
            if type == NotificationType.connection.rawValue {
                content.categoryIdentifier = "CONNECTION_REQUEST"
            } else if type == NotificationType.suggestion.rawValue {
                content.categoryIdentifier = "SUGGESTION_REQUEST"
            }
        }
        
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
        // Handle notification actions
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "ACCEPT_CONNECTION":
            // Handle accept connection
            if let userId = userInfo["connectedUserId"] as? String,
               let userName = userInfo["connectedUserName"] as? String {
                Task {
                    // Implement connection acceptance logic
                    print("User accepted connection with user ID: \(userId), name: \(userName)")
                    // You would typically call your connection service here
                }
            }
            
        case "DECLINE_CONNECTION":
            // Handle decline connection
            if let userId = userInfo["connectedUserId"] as? String {
                Task {
                    // Implement connection decline logic
                    print("User declined connection with user ID: \(userId)")
                    // You would typically call your connection service here
                }
            }
            
        case "VIEW_SUGGESTION":
            // Handle view suggestion profile
            if let userId = userInfo["suggestedUserId"] as? String {
                Task {
                    print("User wants to view profile of suggested user ID: \(userId)")
                    // Navigate to profile or show more info
                }
            }
            
        case "DISMISS_SUGGESTION":
            // Handle dismiss suggestion
            if let userId = userInfo["suggestedUserId"] as? String {
                Task {
                    print("User dismissed suggestion for user ID: \(userId)")
                    // Mark suggestion as dismissed in your database
                }
            }
            
        default:
            // Handle regular notification tap
            if let type = userInfo["type"] as? String {
                switch type {
                case NotificationType.connection.rawValue:
                    print("User tapped on connection notification")
                    // Navigate to connections screen
                    
                case NotificationType.suggestion.rawValue:
                    print("User tapped on suggestion notification")
                    // Navigate to suggestions screen
                    
                case NotificationType.proximity.rawValue:
                    print("User tapped on proximity notification")
                    // Navigate to nearby users screen
                    
                case NotificationType.teamAnnouncement.rawValue:
                    print("User tapped on announcement notification")
                    // Navigate to announcements screen
                    
                default:
                    break
                }
            }
        }
        
        completionHandler()
    }
    
    // MARK: - Remote Notification Handling
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Received remote notification: \(userInfo)")
        
        // Process the notification payload
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let body = alert["body"] as? String,
           let type = userInfo["type"] as? String,
           let notificationType = NotificationType(rawValue: type) {
            
            Task {
                do {
                    try await createNotificationFromRemote(title: title, body: body, type: notificationType, metadata: userInfo)
                    completionHandler(.newData)
                } catch {
                    print("Error processing remote notification: \(error.localizedDescription)")
                    completionHandler(.failed)
                }
            }
        } else {
            completionHandler(.noData)
        }
    }
}

// MARK: - MessagingDelegate Extension
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        if let token = fcmToken {
            saveTokenToFirestore(token: token)
        }
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

// MARK: - Helper Extensions
extension FirestoreNotificationItem {
    // Add a mutating property for read status since we need to update it
    fileprivate mutating func markAsRead() {
        read = true
    }
}
