//
//  NotificationsView 2.swift
//  iOSApp
//
//  Created by S on 18/12/24.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct NotificationsView: View {
    @State private var notifications: [FirestoreNotificationItem] = []
    @State private var isNavigationActive: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Notifications...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if notifications.isEmpty {
                    // Empty state with a clear message
                    VStack {
                        Image(systemName: "bell.slash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("No Notifications")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("You're all caught up!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationCard(
                                title: notification.title, 
                                subtitle: notification.subtitle, 
                                timestamp: notification.timestamp,
                                type: notification.type
                            )
                            .listRowInsets(EdgeInsets())
                            .overlay(Divider(), alignment: .bottom)
                        }
                        .onDelete(perform: deleteNotifications)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(
                trailing: Button(action: {
                    markAllNotificationsAsRead()
                }) {
                    Text("Mark All Read")
                        .foregroundColor(.blue)
                }
            )
        }
        .onAppear {
            fetchNotifications()
        }
        .refreshable {
            fetchNotifications()
        }
    }
    
    // Fetch notifications for the current user
    func fetchNotifications() {
        isLoading = true
        errorMessage = nil
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please log in to view notifications"
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .order(by: "timestamp", descending: true)
            .getDocuments { (querySnapshot, err) in
                isLoading = false
                
                if let err = err {
                    errorMessage = "Failed to fetch notifications: \(err.localizedDescription)"
                    return
                }
                
                notifications = querySnapshot?.documents.compactMap { document in
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
            }
    }
    
    // Delete selected notifications
    func deleteNotifications(at offsets: IndexSet) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        offsets.forEach { index in
            let notification = notifications[index]
            let notificationRef = db.collection("Notifications")
                .document(currentUserId)
                .collection("UserNotifications")
                .document(notification.id)
            
            batch.deleteDocument(notificationRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error deleting notifications: \(error)")
            } else {
                notifications.remove(atOffsets: offsets)
            }
        }
    }
    
    // Mark all notifications as read
    func markAllNotificationsAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        notifications.forEach { notification in
            if !notification.read {
                let notificationRef = db.collection("Notifications")
                    .document(currentUserId)
                    .collection("UserNotifications")
                    .document(notification.id)
                
                batch.updateData(["read": true], forDocument: notificationRef)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error marking notifications as read: \(error)")
            } else {
                // Update local state to reflect read status
                notifications = notifications.map { 
                    var updatedNotification = $0
                    updatedNotification.read = true
                    return updatedNotification
                }
            }
        }
    }
}

// Updated notification data model to include read status
struct FirestoreNotificationItem: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var timestamp: Date
    var type: String
    var read: Bool = false
}

// Updated NotificationCard to show read/unread state
struct NotificationCard: View {
    var title: String
    var subtitle: String
    var timestamp: Date
    var type: String
    
    var body: some View {
        HStack {
            // Indicator for notification type/read status
            Rectangle()
                .fill(type == "new_connection" ? Color.green : 
                      type == "proximity_alert" ? Color.orange : Color.blue)
                .frame(width: 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text(timeFormatted(timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    func timeFormatted(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}