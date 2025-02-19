import SwiftUI
import Firebase

// MARK: - NotificationsView
struct NotificationsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [FirestoreNotificationItem] = []
    @State private var isLoading = true
    @State private var isNavigationActive = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showClearConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    private let animation: Animation = .easeInOut(duration: 0.3)
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                contentView
                
                if isLoading {
                    loadingView
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error)
            }
            .confirmationDialog(
                "Clear All Notifications",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    Task { await clearAllNotifications() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .refreshable {
                await loadNotifications()
            }
            .task {
                await loadNotifications()
            }
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if notifications.isEmpty && !isLoading {
            emptyStateView
        } else {
            notificationListView
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .opacity(0.8)
            
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundStyle(.secondary)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text("You're all caught up!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Notification List View
    private var notificationListView: some View {
        List {
            ForEach(notifications) { notification in
                NotificationCell(notification: notification)
                    .swipeActions(allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await deleteNotification(notification)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        if !notification.read {
                            Button {
                                Task {
                                    await markAsRead(notification)
                                }
                            } label: {
                                Label("Mark Read", systemImage: "checkmark.circle")
                            }
                            .tint(.blue)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !notifications.isEmpty {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Text("Clear All")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    
    // MARK: - Methods
    private func loadNotifications() async {
        isLoading = true
        do {
            notifications = try await NotificationManager.shared.fetchNotifications()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    private func deleteNotification(_ notification: FirestoreNotificationItem) async {
        do {
            try await NotificationManager.shared.deleteNotification(notificationId: notification.id)
            withAnimation(animation) {
                notifications.removeAll { $0.id == notification.id }
            }
        } catch {
            errorMessage = "Failed to delete notification"
            showError = true
        }
    }
    
    private func markAsRead(_ notification: FirestoreNotificationItem) async {
        do {
            try await NotificationManager.shared.markAsRead(notificationId: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].read = true
            }
        } catch {
            errorMessage = "Failed to mark notification as read"
            showError = true
        }
    }
    
    private func clearAllNotifications() async {
        do {
            try await NotificationManager.shared.clearAllNotifications()
            withAnimation(animation) {
                notifications.removeAll()
            }
        } catch {
            errorMessage = "Failed to clear notifications"
            showError = true
        }
    }
}

// MARK: - NotificationCell
struct NotificationCell: View {
    let notification: FirestoreNotificationItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(notification.read ? .regular : .semibold)
                
                Spacer()
                
                Text(timeAgo(from: notification.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(notification.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !notification.read {
                Capsule()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    NotificationsView()
}

// MARK: - Helper Extensions
extension FirestoreNotificationItem {
    // Add a mutating property for read status since we need to update it
    // This extends the original struct from NotificationManager
    fileprivate mutating func markAsRead() {
        read = true
    }
}
