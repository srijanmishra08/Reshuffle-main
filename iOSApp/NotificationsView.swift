import SwiftUI
import MapKit

struct NotificationsView: View {
    @State private var user = BusinessCard(id: UUID(), name: "", profession: "", email: "", company: "", role: "", description: "", phoneNumber: "", whatsapp: "", address: "", website: "", linkedIn: "", instagram: "", xHandle: "", region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                                           trackingMode: .follow)
    @State private var notifications: [NotificationItem] = [
        NotificationItem(title: "New Connection", subtitle: "Someone added your card.", timestamp: Date()),
        NotificationItem(title: "Suggested Connection", subtitle: "You might know John from the office.", timestamp: Date().addingTimeInterval(-3600)),
        NotificationItem(title: "New Messages", subtitle: "You have messages from multiple contacts.", timestamp: Date().addingTimeInterval(-7200)),
        NotificationItem(title: "Event Reminder", subtitle: "Don't forget the networking event tomorrow!", timestamp: Date().addingTimeInterval(3600)),
        NotificationItem(title: "Project Update", subtitle: "Review the latest project updates and provide feedback.", timestamp: Date().addingTimeInterval(7200)),
        NotificationItem(title: "Follow-up Call", subtitle: "Schedule a follow-up call with the client.", timestamp: Date().addingTimeInterval(10800)),
    ]
    @State private var isNavigationActive: Bool = false

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
                .navigationBarTitle("Notifications", displayMode: .inline)
                .navigationBarItems(leading: backButton)
                .background(
//                    NavigationLink(destination: MyCards(user: $user).navigationBarBackButtonHidden(true), isActive: $isNavigationActive) {
//                        EmptyView()
//                    }
                    NavigationLink(destination: MyCards().navigationBarBackButtonHidden(true), isActive: $isNavigationActive) {
                        EmptyView()
                    }
                )
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

        func deleteNotification(at offsets: IndexSet) {
            notifications.remove(atOffsets: offsets)
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
        return formatter.string(from: date)
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}

struct NotificationItem: Identifiable {
    var id = UUID()
    var title: String
    var subtitle: String
    var timestamp: Date
}
