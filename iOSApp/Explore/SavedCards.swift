import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct CardListView: View {
    
    @State private var searchCards: String = ""
        @State private var contacts: [Contact] = []
        
        var body: some View {
//            NavigationStack {
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
                                      .placeholder(when: searchCards.isEmpty) {
                                          Text("Search contacts")
                                              .foregroundColor(.secondary)
                                      }
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
                                      ContactCard(contact: contact)
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
    
    func fetchData() {
            guard let currentUserUID = Auth.auth().currentUser?.uid else {
                return
            }

            let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserUID)

            savedUsersRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let scannedUIDs = document.data()?["scannedUIDs"] as? [String] {
                        for scannedUID in scannedUIDs {
                            fetchUserDetails(for: scannedUID)
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
                    lastName: "",  // Set default or remove if unnecessary
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

                // Add contact to the list without requiring all fields
                self.contacts.append(contact)
                print(contacts)
            } else {
                print("Error fetching UserDatabase document for UID \(uid): \(error?.localizedDescription ?? "")")
            }
        }
    }

}
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder then: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            then()
                .opacity(shouldShow ? 1 : 0)
            
            self
        }
    }
}

// Update ContactCard to use system colors
struct ContactCard: View {
    let contact: Contact
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
            DetailsPopupView(contact: contact)
        }
    }
}
//
//struct CardListItemView: View {
//    let contact: Contact
//    @State private var showDetails = false
////    @Environment(\.presentationMode) var presentationMode
//
//
//    var body: some View {
//        Button(action: {
//            self.showDetails.toggle()
//        }) {
//            HStack {
//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .frame(width: 40, height: 40)
//                    .foregroundColor(.black)
//                    .padding(.trailing, 8)
//
//                VStack(alignment: .leading) {
//                    Text("\(contact.firstName)")
//                        .font(.headline)
//                    Text("\(contact.designation), \(contact.company)")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//                }
//            }
//            .padding(8)
//        }
//        .sheet(isPresented: $showDetails) {
//            DetailsPopupView(contact: contact)
//        }
//    }
//}

struct DetailsPopupView: View {
    let contact: Contact
    @State private var userData: UserDataBusinessCard?
    @State private var isFetchingData = false
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
//            .navigationTitle(contact.firstName)
//            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                }
            )
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
        
        print("Attempting to fetch user with email: \(contact.email)")
        
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
                        print("No documents found for email: \(self.contact.email)")
                        return
                    }

                    // Detailed document data print
                    let documentData = document.data()
                    print("Full Document Data: \(documentData)")
                    
                    // Check for missing keys
                    let requiredKeys = ["name", "profession", "role", "company", "email", "phoneNumber", "website", "address", "linkedIn", "instagram", "xHandle", "cardColor"]
                    let missingKeys = requiredKeys.filter { !documentData.keys.contains($0) }
                    
                    if !missingKeys.isEmpty {
                        print("Missing keys in document: \(missingKeys)")
                    }

                    do {
                        // Try decoding manually
                        let jsonData = try JSONSerialization.data(withJSONObject: documentData, options: [])
                        let decoder = JSONDecoder()
                        let user = try decoder.decode(UserDataBusinessCard.self, from: jsonData)
                        userData = user
                    } catch {
                        print("Decoding Error Type: \(type(of: error))")
                        print("Detailed Decoding Error: \(error)")
                        print("Decoding Error Description: \(error.localizedDescription)")
                    }
                }
            }
    }
    }

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
