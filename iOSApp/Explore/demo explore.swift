import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

// MARK: - Model
struct UserCard: Identifiable {
    var id = UUID()
    var name: String
    var role: String
    var company: String
    var category: String
}

// MARK: - ViewModel
// MARK: - ViewModel
// MARK: - ViewModel
class ExploreViewModel: ObservableObject {
    @Published var userCards: [UserCard] = [
        UserCard(name: "Alice Johnson", role: "Product Manager", company: "TechCorp", category: "Tech"),
        UserCard(name: "Bob Smith", role: "Software Engineer", company: "Innovate Ltd", category: "Tech"),
        UserCard(name: "Carol White", role: "Designer", company: "Creative Studios", category: "Design")
    ]
    @Published var searchText = ""
    @Published var selectedCategory: String? = nil
    @Published var showCategoryPopup = false
    @Published var isCardListActive = false

    // Filter userCards based on searchText and selectedCategory
    var filteredUserCards: [UserCard] {
        userCards.filter { card in
            let matchesSearchText = searchText.isEmpty || card.name.localizedCaseInsensitiveContains(searchText) ||
                                    card.role.localizedCaseInsensitiveContains(searchText) ||
                                    card.company.localizedCaseInsensitiveContains(searchText)
            
            // Matches category, accounting for "All Cards" to show all
            let matchesCategory = selectedCategory == nil || selectedCategory == "All Cards" || card.category == selectedCategory
            
            return matchesSearchText && matchesCategory
        }
    }
    
    init() {
        fetchUserCards() // Fetch Firebase data when ViewModel is initialized
    }

    func selectCategory(_ category: String?) {
        // Set selectedCategory to nil for "All Cards" to display all items
        selectedCategory = (category == "All Cards") ? nil : category
    }
    private let db = Firestore.firestore()
    func saveUserCard(for uid: String) {
            guard let currentUserUID = Auth.auth().currentUser?.uid else {
                print("User not authenticated")
                return
            }
        
            let currentUserRef = db.collection("SavedUsers").document(currentUserUID)

            currentUserRef.getDocument { document, error in
                if let error = error {
                    print("Error fetching document: \(error.localizedDescription)")
                    return
                }

                var scannedUIDs = [String]()
                if let document = document, document.exists {
                    if var data = document.data(), let existingUIDs = data["scannedUIDs"] as? [String] {
                        scannedUIDs = existingUIDs
                    }
                }

                if !scannedUIDs.contains(uid) {
                    scannedUIDs.append(uid)
                    currentUserRef.setData(["scannedUIDs": scannedUIDs], merge: true) { error in
                        if let error = error {
                            print("Error saving card: \(error.localizedDescription)")
                        } else {
                            print("Card saved successfully")
                        }
                    }
                } else {
                    print("Card already saved")
                }
            }
        }

    func fetchUserCards() {
        let db = Firestore.firestore()
        
        db.collection("UserDatabase").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user cards: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }

            self.userCards.removeAll()

            for document in documents {
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let role = data["profession"] as? String,
                      let company = data["company"] as? String else {
                    print("Missing or invalid data for user with ID: \(document.documentID)")
                    continue
                }
                
                // Determine category based on profession with added roles
                let category: String
                switch role.lowercased() {
                    case "product manager", "software engineer", "developer", "sde", "data scientist", "network administrator", "web developer", "lead ios developer", "ios developer", "ux/ui designer", "database administrator", "devops engineer", "it consultant", "system analyst", "cybersecurity analyst", "mobile app developer", "ai/machine learning engineer", "game developer", "qa tester", "cloud solutions architect", "tech support specialist", "technical writer", "embedded systems engineer", "network engineer", "full stack developer", "tester":
                        category = "Tech"
                    case "general practitioner", "cardiologist", "dentist", "orthopedic surgeon", "pediatrician", "ophthalmologist", "psychiatrist", "neurologist", "obstetrician/gynecologist", "anesthesiologist", "radiologist", "pathologist", "general surgeon", "emergency medicine physician", "family medicine physician", "urologist", "dermatologist", "oncologist", "endocrinologist", "nephrologist","doctor":
                        category = "Doctor"
                    case "student", "teacher", "professor":
                        category = "Education"
                    case "plumber", "electrician", "hvac technician", "carpenter", "mechanic", "locksmith", "landscaper", "painter", "pool cleaner", "appliance repair technician", "roofing contractor", "pest control technician", "septic tank services", "glass installer", "welder", "solar panel installer", "elevator mechanic", "building inspector", "fire alarm technician", "masonry worker":
                        category = "Utility"
                    case "actor", "musician", "video game developer", "film director", "cinematographer", "sound engineer", "choreographer", "costume designer", "makeup artist", "stunt performer", "film editor", "set designer", "casting director", "storyboard artist", "location manager", "voice actor", "script supervisor", "film producer", "entertainment lawyer", "talent agent":
                        category = "Entertainment"
                    case "painter", "sculptor", "graphic designer", "photographer", "illustrator", "printmaker", "ceramic artist", "textile designer", "jewelry designer", "glassblower", "digital artist", "street artist", "installation artist", "muralist", "collage artist", "comic book artist", "cartoonist", "conceptual artist", "mixed media artist", "tattoo artist":
                        category = "Artist"
                    case "project manager", "hr manager", "financial analyst", "marketing manager", "operations manager", "sales manager", "supply chain manager", "business analyst", "quality assurance manager", "risk manager", "it manager", "event planner", "public relations manager", "brand manager", "facilities manager", "customer success manager", "research and development manager", "training and development manager", "legal operations manager":
                        category = "Management"
                    default:
                        category = "Others"
                }
                
                let userCard = UserCard(
                    id: UUID(uuidString: document.documentID) ?? UUID(),
                    name: name,
                    role: role,
                    company: company,
                    category: category
                )

                DispatchQueue.main.async {
                    self.userCards.append(userCard)
                }
            }
        }
    }

}


// MARK: - View
struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        VStack {
            // Search Bar
            HStack {
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                NavigationLink(destination: NextView()) {
                    Image(systemName: "map")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                }
                .padding(.top, 16)
                .padding(.trailing)
            }

            Spacer()
            // Scrollable User Cards List
            ScrollView {
                Spacer()
                VStack(spacing: 16) {
                    ForEach(viewModel.filteredUserCards) { card in
                        UserCardView(card: card, viewModel: viewModel)
                            .padding(.horizontal)
                    }
                }
            }.background(Color(.white))
            
            Spacer()
            
            // Category Pop-Up
            if viewModel.showCategoryPopup {
                CategoryPopupView(viewModel: viewModel)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.showCategoryPopup)
                    .padding(.bottom, 20)
            }
        }
        .background(Color(.white))
        .onAppear {
            withAnimation {
                viewModel.showCategoryPopup = true
            }
        }
    }
}

// MARK: - SearchBar View
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        TextField("🔍    Search names, companies, and professions", text: $text)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal, 16)
    }
}

// MARK: - UserCardView
// MARK: - UserCardView
struct UserCardView: View {
    let card: UserCard
    @ObservedObject var viewModel: ExploreViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.name)
                .font(.headline)
                .foregroundColor(.white) // White text for contrast
            Text(card.role)
                .font(.subheadline)
                .foregroundColor(.white)
            Text(card.company)
                .font(.subheadline)
                .foregroundColor(.white)
            
            // Save Button
            // Save Button
            Button(action: {
                // Assuming you want to save the user's ID, you need to pass the card's ID (or any relevant identifier)
                viewModel.saveUserCard(for: card.id.uuidString) // Pass the card ID as a String
            }) {
                Text("Save")
                    .padding(8)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 36/255.0, green: 143/255.0, blue: 152/255.0)) // Custom card background color
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal, 0)
    }
}

// MARK: - CategoryPopupView
struct CategoryPopupView: View {
    @ObservedObject var viewModel: ExploreViewModel

    let categoryIcons: [String: String] = [
        "All Cards": "square.grid.2x2",
        "Tech": "desktopcomputer",
        "Doctor": "staroflife",
        "Education": "book",
        "Utility": "wrench.and.screwdriver",
        "Entertainment": "gamecontroller",
        "Artist": "paintpalette",
        "Management": "briefcase",
        "Others": "ellipsis.circle"
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Categories")
                .font(.title.bold())
                

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    ForEach(categoryIcons.keys.sorted(), id: \.self) { category in
                        Button(action: {
                            viewModel.selectCategory(viewModel.selectedCategory == category ? nil : category)
                        }) {
                            VStack {
                                Image(systemName: categoryIcons[category] ?? "questionmark.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(viewModel.selectedCategory == category ? .blue : .primary)
                                Text(category)
                                    .font(.caption)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundColor(viewModel.selectedCategory == category ? .blue : .primary)
                            }
                            .padding()
                            .frame(width: 90, height: 90)
                            .background(viewModel.selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 5)
                    }
                }
            }

            // Saved Cards Button inside the popup
            Button("Saved Cards") {
                viewModel.isCardListActive = true
            }
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
            .foregroundColor(.black)
            .padding(.top, 10)
            

            // Navigation to Saved Cards
            NavigationLink(
                destination: CardListView(),
                isActive: $viewModel.isCardListActive
            ) {
                EmptyView()
            }
            .hidden()
        }
        .padding(.horizontal)
        .cornerRadius(16)
        
    }
}


// MARK: - Preview
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
