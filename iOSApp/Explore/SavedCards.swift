import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct CardListView: View {
    
    @State private var searchCards: String = ""
    @State private var contacts: [Contact] = []

    var body: some View {
//        this might not be neccassary to be inside a navigation stack because you arent navigating to another page.check it once.
        NavigationStack {
            VStack {
//                Text("Saved Cards")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .padding()

                TextField("🔍    Search names, companies, and professions", text: $searchCards)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))

                List {
                    ForEach(filteredContacts) { contact in
                        CardListItemView(contact: contact)
                    }
                    .onDelete { indices in
                        let deletedContactUIDs = indices.map { contacts[$0].uid }
                        
                        guard let currentUserUID = Auth.auth().currentUser?.uid else {
                            return
                        }
                        
                        let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserUID)
                        
                        savedUsersRef.getDocument { (document, error) in
                            if let document = document, document.exists {
                                var scannedUIDs = document.data()?["scannedUIDs"] as? [String] ?? []
                                
                                for deletedUID in deletedContactUIDs {
                                    if let indexToRemove = scannedUIDs.firstIndex(of: deletedUID) {
                                        scannedUIDs.remove(at: indexToRemove)
                                    }
                                }
                                
                                savedUsersRef.setData(["scannedUIDs": scannedUIDs], merge: true) { error in
                                    if let error = error {
                                        print("Error updating scannedUIDs: \(error.localizedDescription)")
                                    } else {
                                        print("scannedUIDs updated successfully")
                                    }
                                }
                                
                                self.contacts.remove(atOffsets: indices)
                            } else {
                                print("Error fetching SavedUsers document: \(error?.localizedDescription ?? "")")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }.navigationTitle("Saved Cards")
        }
        .onAppear {
            fetchData()
        }
//        .navigationBarTitle("", displayMode: .inline)
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

struct CardListItemView: View {
    let contact: Contact
    @State private var showDetails = false
//    @Environment(\.presentationMode) var presentationMode


    var body: some View {
        Button(action: {
            self.showDetails.toggle()
        }) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.black)
                    .padding(.trailing, 8)

                VStack(alignment: .leading) {
                    Text("\(contact.firstName)")
                        .font(.headline)
                    Text("\(contact.designation), \(contact.company)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(8)
        }
        .sheet(isPresented: $showDetails) {
            DetailsPopupView(contact: contact)
        }
    }
}

struct DetailsPopupView: View {
    let contact: Contact
    @State private var userData: UserDataBusinessCard?
    @State private var isFetchingData = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if let userData = userData {
                BusinessCardSaved(userData: Binding.constant(userData))
                    .padding()
                    .frame(width: 320, height: 380)
            } else {
                if isFetchingData {
                    ProgressView("Fetching user data...")
                } else {
                    Text("Error fetching user data.")
                }
            }
        }
        .onAppear {
            fetchUserDetails()
        }
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
                            print("Error fetching user details: \(error.localizedDescription)")
                            return
                        }

                        guard let documents = querySnapshot?.documents, let document = documents.first else {
                            print("User details not found")
                            return
                        }

                        do {
                            let user = try document.data(as: UserDataBusinessCard.self)
                            userData = user
                        } catch {
                            print("Error decoding user data: \(error.localizedDescription)")
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
