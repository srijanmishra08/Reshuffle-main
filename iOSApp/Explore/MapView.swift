import SwiftUI
import Firebase
import CoreLocation
import MapKit

//// MARK: - UserCard Model
//struct UserCard: Identifiable {
//    var id: String
//    var name: String
//    var role: String
//    var company: String
//    var profession: String
//    var location: CLLocationCoordinate2D // User location
//}

import Combine

// MARK: - MapViewModel
class MapViewModel: ObservableObject {
    @Published var userCards: [UserCard] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    @Published var selectedCard: UserCard? = nil
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private let db = Firestore.firestore()

    // MARK: - Filtered Cards
    var filteredUserCards: [UserCard] {
        userCards.filter { card in
            let matchesSearchText = searchText.isEmpty || card.name.localizedCaseInsensitiveContains(searchText) ||
                                    card.role.localizedCaseInsensitiveContains(searchText) ||
                                    card.company.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || selectedCategory == "All Cards" || card.category == selectedCategory
            
            return matchesSearchText && matchesCategory
        }
    }
    
    // MARK: - Fetch User Cards
    func fetchUserCards() {
        db.collection("UserDatabase").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user cards: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.userCards = documents.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let role = data["profession"] as? String,
                          let company = data["company"] as? String,
                          let latitude = data["latitude"] as? Double,
                          let longitude = data["longitude"] as? Double,
                          let profession = data["category"] as? String else {
                        print("Missing or invalid data for user with ID:")
                        continue
                    }
                    
                    return UserCard(
                        id: id,
                        uid: doc.documentID,
                        name: name,
                        role: role,
                        company: company,
                        profession: profession,
                        location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    )
                }
            }
        }
    }
    
    // MARK: - Save User Card
    func saveUserCard(card: UserCard) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        
        let ref = db.collection("SavedUsers").document(currentUserUID)
        ref.updateData(["savedCards": FieldValue.arrayUnion([card.id])]) { error in
            if let error = error {
                print("Error saving card: \(error.localizedDescription)")
            } else {
                print("Card saved successfully.")
            }
        }
    }
    
    // MARK: - Select Category
    func selectCategory(_ category: String?) {
        selectedCategory = (category == "All Cards") ? nil : category
    }
}

import MapKit

// MARK: - MapView
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        VStack {
            // MARK: - Search Bar
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // MARK: - Map View
            Map(coordinateRegion: $viewModel.mapRegion, annotationItems: viewModel.filteredUserCards) { card in
                MapAnnotation(coordinate: card.location) {
                    Button(action: {
                        viewModel.selectedCard = card
                    }) {
                        Circle()
                            .fill(colorForCategory(card.category))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(10)
            .padding(.horizontal)
            
            // MARK: - Selected Card Details
            if let selectedCard = viewModel.selectedCard {
                VStack(spacing: 10) {
                    Text("Name: \(selectedCard.name)")
                        .font(.headline)
                    Text("Role: \(selectedCard.role)")
                        .font(.subheadline)
                    Text("Company: \(selectedCard.company)")
                        .font(.subheadline)
                    
                    Button(action: {
                        viewModel.saveUserCard(card: selectedCard)
                    }) {
                        Text("Save Card")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()
            }
            
            // MARK: - Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(["All Cards", "Tech", "Doctor", "Artist", "Education", "Management", "Utility", "Entertainment"], id: \.self) { category in
                        Button(action: {
                            viewModel.selectCategory(category)
                        }) {
                            Text(category)
                                .foregroundColor(.white)
                                .padding()
                                .background(colorForCategory(category))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            viewModel.fetchUserCards()
        }
    }
    
    // MARK: - Helper Function for Colors
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Tech": return .blue
        case "Doctor": return .green
        case "Artist": return .purple
        case "Education": return .orange
        case "Management": return .red
        case "Utility": return .yellow
        case "Entertainment": return .pink
        default: return .gray
        }
    }
}
