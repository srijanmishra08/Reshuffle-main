import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

// MARK: - Model
struct UserCard: Identifiable {
    var id: String // Firebase document ID
    var uid: String // User's unique identifier
    var name: String
    var role: String
    var profession: String
    var company: String
    var category: String
    var cardColor: String? 
    
}


// MARK: - ViewModel
// MARK: - ViewModel
// MARK: - ViewModel
class ExploreViewModel: ObservableObject {
    @Published var userCards: [UserCard] = []
    @Published var searchText = ""
    @Published var selectedCategory: String? = nil
    @Published var showCategoryPopup = false

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
                    if let data = document.data(), let existingUIDs = data["scannedUIDs"] as? [String] {
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
                      let uid = data["uid"] as? String,
                      let profession = data["profession"]as? String,
                      let role = data["role"] as? String,
                      let company = data["company"] as? String else {
                    print("Missing or invalid data for user with ID: \(document.documentID)")
                    continue
                }
                // Fetch custom card color if available, otherwise use nil
                                let cardColor = data["cardColor"] as? String
                
                // Determine category based on profession with added roles
                let category: String
                switch role.lowercased() {
                    case "product manager", "software engineer", "developer", "sde", "data scientist", "network administrator", "web developer", "lead ios developer", "ios developer", "ux/ui designer", "database administrator", "devops engineer", "it consultant", "system analyst", "cybersecurity analyst", "mobile app developer", "ai/machine learning engineer", "game developer", "qa tester", "cloud solutions architect", "tech support specialist", "technical writer", "embedded systems engineer", "network engineer", "full stack developer", "tester":
                        category = "Tech"
                    case "general practitioner", "cardiologist", "dentist", "orthopedic surgeon", "pediatrician", "ophthalmologist", "psychiatrist", "neurologist", "obstetrician/gynecologist", "anesthesiologist", "radiologist", "pathologist", "general surgeon", "emergency medicine physician", "family medicine physician", "urologist", "dermatologist", "oncologist", "endocrinologist", "nephrologist","doctor":
                        category = "Doctor"
                    case "student", "teacher", "professor":
                        category = "Education"
                    case "plumber", "electrician", "hvac technician", "carpenter", "mechanic", "locksmith", "landscaper"/*, "painter"*/, "pool cleaner", "appliance repair technician", "roofing contractor", "pest control technician", "septic tank services", "glass installer", "welder", "solar panel installer", "elevator mechanic", "building inspector", "fire alarm technician", "masonry worker":
                        category = "Utility"
                    case "actor", "musician", "video game developer", "film director", "cinematographer", "sound engineer", "choreographer", "costume designer", "makeup artist", "stunt performer", "film editor", "set designer", "casting director", "storyboard artist", "location manager", "voice actor", "script supervisor", "film producer", "entertainment lawyer", "talent agent":
                        category = "Entertainment"
                    case "painter", "sculptor", "graphic designer", "photographer", "illustrator", "printmaker", "ceramic artist", "textile designer", "jewelry designer", "glassblower", "digital artist", "street artist", "installation artist", "muralist", "collage artist", "comic book artist", "cartoonist", "conceptual artist", "mixed media artist", "tattoo artist","artist":
                        category = "Artist"
                    case "project manager", "hr manager", "financial analyst", "marketing manager", "operations manager", "sales manager", "supply chain manager", "business analyst", "quality assurance manager", "risk manager", "it manager", "event planner", "public relations manager", "brand manager", "facilities manager", "customer success manager", "research and development manager", "training and development manager", "legal operations manager":
                        category = "Management"
                    default:
                        category = "Others"
                }
                
                let userCard = UserCard(
                                    id: document.documentID,
                                    uid: uid,
                                    name: name,
                                    role: role, profession: profession,
                                    company: company,
                                    category: category,
                                    cardColor: cardColor
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Welcome Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Discover Professionals")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary) // Adapts to color scheme
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Search Bar Section
                HStack(spacing: 16) {
                    SearchBar(text: $viewModel.searchText)
                    
                    NavigationLink(destination: NextView()) {
                        Image(systemName: "map")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                                    .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)

                ScrollView {
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Browse Categories")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        CategoryPopupView(viewModel: viewModel)
                    }
                    .padding(.bottom, 24)
                  
                    // Cards Section
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Text(viewModel.selectedCategory ?? "All Professionals")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(viewModel.filteredUserCards.count) results")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Cards List
                        VStack(spacing: 16) {
                            if viewModel.filteredUserCards.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No professionals found")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Try adjusting your search or category filters")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(viewModel.filteredUserCards) { card in
                                    UserCardView(card: card, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Saved Cards Button
                NavigationLink(destination: CardListView().navigationBarBackButtonHidden(false)) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("View Saved Cards")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

// MARK: - SearchBar View
struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Search by name, role, or company", text: $text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .tint(.blue)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - CategoryPopupView
struct CategoryPopupView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Environment(\.colorScheme) private var colorScheme

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
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(categoryIcons.keys.sorted(), id: \.self) { category in
                        VStack {
                            Button(action: {
                                viewModel.selectCategory(viewModel.selectedCategory == category ? nil : category)
                            }) {
                                Image(systemName: categoryIcons[category] ?? "questionmark.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                                    .padding(15)
                                    .background(
                                        viewModel.selectedCategory == category
                                        ? Color.blue
                                        : Color.primary.opacity(0.1)
                                    )
                                    .clipShape(Circle())
                            }
                            
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}



// MARK: - UserCardView
// MARK: - UserCardView
struct UserCardView: View {
    let card: UserCard
    @ObservedObject var viewModel: ExploreViewModel
    
    // Helper function to convert color string to Color
    func parseColor(_ colorString: String?) -> Color {
        guard let colorString = colorString else {
            return Color(red: 36/255.0, green: 143/255.0, blue: 152/255.0)
        }
        
        let cleanColorString = colorString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: cleanColorString)
        var hexNumber: UInt64 = 0
        
        if scanner.scanHexInt64(&hexNumber) {
            let red = Double((hexNumber & 0xff0000) >> 16) / 255.0
            let green = Double((hexNumber & 0x00ff00) >> 8) / 255.0
            let blue = Double(hexNumber & 0x0000ff) / 255.0
            
            return Color(red: red, green: green, blue: blue)
        }
        
        return Color(red: 36/255.0, green: 143/255.0, blue: 152/255.0)
    }

    var body: some View {
        ZStack {
            // Card Background
            parseColor(card.cardColor)
                .overlay(
                    // Gradient overlay for better text readability
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Content
            HStack(alignment: .top, spacing: 0) {
                // Left side content
                VStack(alignment: .leading, spacing: 12) {
                    // Name with larger, bolder font
                    Text(card.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Role and company with custom styling
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.role)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 4) {
                            Text("at")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(card.company)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // Profession with subtle styling
                    Text(card.profession)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 4)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save button on the right
                VStack {
                    Button(action: {
                        viewModel.saveUserCard(for: card.uid)
                    }) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
            }
        }.frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}
// MARK: - Preview
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
            ExploreView()
//        }
//        .navigationViewStyle(.stack) // Ensures consistent behavior in iOS
//
    }
}
