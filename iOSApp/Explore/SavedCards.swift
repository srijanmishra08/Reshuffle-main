import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct CardListView: View {
    @State private var searchCards: String = ""
    @State private var contacts: [Contact] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Improved Search Bar
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading)
                    
                    TextField("Search contacts", text: $searchCards)
                        .foregroundColor(.primary)
                        .accentColor(.blue)
//                        .placeholder(when: searchCards.isEmpty) {
//                            Text("Search contacts")
//                                .foregroundColor(.secondary)
//                        }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            .padding(.top)
            
            // Contacts List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredContacts) { contact in
                        ContactCard(contact: contact, onDelete: { deletedContact in
                            deleteContact(deletedContact)
                        })
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                              removal: .scale.combined(with: .opacity)))
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitle("My Contacts")
        .onAppear {
            fetchData()
        }
    }
    
    var filteredContacts: [Contact] {
        if searchCards.isEmpty {
            return contacts
        } else {
            return contacts.filter { $0.matches(search: searchCards) }
        }
    }
    
    func deleteContact(_ contact: Contact) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        
        let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserUID)
        
        // Remove the contact from Firestore
        savedUsersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var scannedUIDs = document.data()?["scannedUIDs"] as? [String] {
                    scannedUIDs.removeAll { $0 == contact.uid }
                    
                    // Update Firestore
                    savedUsersRef.updateData([
                        "scannedUIDs": scannedUIDs
                    ]) { error in
                        if let error = error {
                            print("Error updating document: \(error)")
                        } else {
                            // Remove contact from local array
                            DispatchQueue.main.async {
                                contacts.removeAll { $0.uid == contact.uid }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchData() {
        contacts.removeAll()
        
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserUID)
        
        savedUsersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let scannedUIDs = document.data()?["scannedUIDs"] as? [String] {
                    var processedUIDs = Set<String>()
                    
                    for scannedUID in scannedUIDs {
                        if !processedUIDs.contains(scannedUID) {
                            processedUIDs.insert(scannedUID)
                            fetchUserDetails(for: scannedUID)
                        }
                    }
                }
            } else {
                print("Error fetching SavedUsers document: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func fetchUserDetails(for uid: String) {
        let userDatabaseRef = Firestore.firestore().collection("UserDatabase").document(uid)
        
        userDatabaseRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                let contact = Contact(
                    uid: uid,
                    firstName: data["name"] as? String ?? "Unknown",
                    lastName: "",
                    designation: data["profession"] as? String ?? "Unknown",
                    company: data["company"] as? String ?? "Unknown",
                    coordinate: CLLocationCoordinate2D(),
                    email: data["email"] as? String ?? "",
                    role: data["role"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    whatsapp: data["whatsapp"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    website: data["website"] as? String ?? "",
                    linkedIn: data["linkedIn"] as? String ?? "",
                    instagram: data["instagram"] as? String ?? "",
                    xHandle: data["xHandle"] as? String ?? ""
                )
                
                DispatchQueue.main.async {
                    if !self.contacts.contains(where: { $0.uid == contact.uid }) {
                        self.contacts.append(contact)
                    }
                }
            }
        }
    }
}

struct ContactCard: View {
    let contact: Contact
    let onDelete: (Contact) -> Void
    @State private var showDetails = false
    
    var body: some View {
        Button(action: { showDetails.toggle() }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.firstName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(contact.designation) • \(contact.company)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .imageScale(.small)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.primary.opacity(0.05), radius: 1, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetails) {
            DetailsPopupView(contact: contact, onDelete: {
                showDetails = false
                onDelete(contact)
            })
        }
    }
}

struct DetailsPopupView: View {
    let contact: Contact
    let onDelete: () -> Void
    @State private var userData: UserDataBusinessCard?
    @State private var isFetchingData = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if let userData = userData {
                    BusinessCardSaved(userData: Binding.constant(userData))
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                              removal: .scale.combined(with: .opacity)))
                } else {
                    contentPlaceholder
                }
            }
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                },
                trailing: Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            )
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Contact"),
                    message: Text("Are you sure you want to delete this contact? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        onDelete()
                    },
                    secondaryButton: .cancel()
                )
            }
            .padding()
        }
        .interactiveDismissDisabled(isFetchingData)
        .onAppear {
            fetchUserDetails()
        }
    }
    
    private var contentPlaceholder: some View {
        VStack(spacing: 20) {
            if isFetchingData {
                ProgressView("Loading contact details...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.red)
                
                Text("Unable to load contact details")
                    .font(.headline)
                
                Text("Please check your network connection or try again later.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Retry") {
                    fetchUserDetails()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    func fetchUserDetails() {
        isFetchingData = true
        
        Firestore.firestore().collection("UserDatabase")
            .whereField("email", isEqualTo: contact.email)
            .getDocuments { querySnapshot, error in
                DispatchQueue.main.async {
                    defer {
                        isFetchingData = false
                    }

                    if let error = error {
                        print("Firestore Error: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = querySnapshot?.documents, let document = documents.first else {
                        print("No documents found for email: \(contact.email)")
                        return
                    }

                    let documentData = document.data()
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: documentData, options: [])
                        let decoder = JSONDecoder()
                        let user = try decoder.decode(UserDataBusinessCard.self, from: jsonData)
                        userData = user
                    } catch {
                        print("Decoding Error: \(error.localizedDescription)")
                    }
                }
            }
    }
}

// Rest of the code (Contact struct, View extension) remains the same
struct Contact: Identifiable, Equatable, Hashable {
    let id = UUID()
    let uid: String
    let firstName: String
    let lastName: String
    let designation: String
    let company: String
    let coordinate: CLLocationCoordinate2D
    
    let email: String
    let role: String
    let description: String
    let phoneNumber: String
    let whatsapp: String
    let address: String
    let website: String
    let linkedIn: String
    let instagram: String
    let xHandle: String

    func matches(search: String) -> Bool {
        let searchString = search.lowercased()
        return firstName.lowercased().contains(searchString)
            || designation.lowercased().contains(searchString)
            || company.lowercased().contains(searchString)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CardListView_Previews: PreviewProvider {
    static var previews: some View {
        let cardListView = CardListView()
        CardListView()
    }
}
