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

    var filteredUserCards: [UserCard] {
        userCards.filter { card in
            // Check if search text matches name, role, or company
            let matchesSearchText = searchText.isEmpty || card.name.localizedCaseInsensitiveContains(searchText) ||
                                    card.role.localizedCaseInsensitiveContains(searchText) ||
                                    card.company.localizedCaseInsensitiveContains(searchText)
            
            // Check if selectedCategory matches or if "All Cards" is selected
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

    func saveUserCard(_ card: UserCard) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        
        let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserUID)
        
        savedUsersRef.updateData([
            "scannedUIDs": FieldValue.arrayUnion([card.id.uuidString])
        ]) { error in
            if let error = error {
                print("Error saving user card: \(error.localizedDescription)")
            } else {
                print("User card saved successfully")
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
                      let company = data["company"] as? String,
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double else {
                    print("Missing or invalid data for user with ID: \(document.documentID)")
                    continue
                }
                
                let category = data["category"] as? String ?? "Unknown Category"

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
            }.background(Color(.gray))
            
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
struct UserCardView: View {
    let card: UserCard
    @ObservedObject var viewModel: ExploreViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.name)
                .font(.headline)
                .foregroundColor(.primary)
            Text(card.role)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(card.company)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Save Button
            Button(action: {
                viewModel.saveUserCard(card)
            }) {
                Text("Save")
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
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
