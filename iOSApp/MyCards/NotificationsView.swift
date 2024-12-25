import SwiftUI
import Firebase
import FirebaseFirestore

struct NotificationsView: View {
    @State private var notifications: [FirestoreNotificationItem] = []
    @State private var isLoading = true
    @State private var isNavigationActive = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Notifications...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationListView
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(
                leading: backButton,
                trailing: clearAllButton
            )
            .background(
                NavigationLink(
                    destination: MyCards().navigationBarBackButtonHidden(true),
                    isActive: $isNavigationActive
                ) {
                    EmptyView()
                }
            )
            .onAppear {
                loadNotifications()
            }
        }
    }
    
    // Empty state view when no notifications
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "bell.slash.fill")
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
    }
    
    // List of notifications
    private var notificationListView: some View {
        List {
            ForEach(notifications) { notification in
                NotificationCard(
                    title: notification.title,
                    subtitle: notification.subtitle,
                    timestamp: notification.timestamp
                )
                .listRowInsets(EdgeInsets())
                .overlay(Divider(), alignment: .bottom)
            }
            .onDelete(perform: deleteNotifications)
        }
        .listStyle(PlainListStyle())
    }
    
    // Back button to previous screen
    private var backButton: some View {
        Button(action: {
            isNavigationActive = true
        }) {
            Image(systemName: "arrow.left")
        }
    }
    
    // Clear all notifications button
    private var clearAllButton: some View {
        Button("Clear All") {
            clearAllNotifications()
        }
        .foregroundColor(.red)
    }
    
    // Load notifications from NotificationManager
    private func loadNotifications() {
        isLoading = true
        NotificationManager.shared.fetchNotifications { fetchedNotifications in
            self.notifications = fetchedNotifications
            self.isLoading = false
        }
    }
    
    // Delete individual notifications
    private func deleteNotifications(at offsets: IndexSet) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        offsets.forEach { index in
            let notification = notifications[index]
            
            // Delete from Firestore
            db.collection("Notifications")
                .document(currentUserId)
                .collection("UserNotifications")
                .document(notification.id)
                .delete { error in
                    if let error = error {
                        print("Error deleting notification: \(error.localizedDescription)")
                    }
                }
        }
        
        // Remove from local array
        notifications.remove(atOffsets: offsets)
    }
    
    // Clear all notifications
    private func clearAllNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Delete all notifications for the current user
        db.collection("Notifications")
            .document(currentUserId)
            .collection("UserNotifications")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                snapshot?.documents.forEach { document in
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting notification: \(error.localizedDescription)")
                        }
                    }
                }
                
                // Clear local notifications array
                notifications.removeAll()
            }
    }
}

// Notification Card View
struct NotificationCard: View {
    var title: String
    var subtitle: String
    var timestamp: Date
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formattedTimestamp)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
    }
    
    // Format timestamp
    private var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
//setup inapp notification
    //create notifications
        //logic-- create a new document in the notifications collection inside the user's document, and set the title, subtitle, and timestamp,
            //NEW CONNETION
            // when a user adds mycard then a notification should be created for that user

            //when i add another user then a notification should be created for that user
            // when i add another user then a notification should be created for me as well
            //SUGGESTED CONNECTION
            //  when a user of my category is present in the proximity
            // custom notifications from the team to all users for networking events

    //send notifications
//setup push notification
//setup local notification


