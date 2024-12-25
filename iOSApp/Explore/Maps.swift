////
////  Maps.swift
////  iOSApp
////
////  Created by S on 29/11/24.
////
//
//import SwiftUI
//import Combine
//import CoreLocation
//import FirebaseFirestore
//import FirebaseFirestoreSwift
//import MapKit
//import FirebaseAuth
//
//// MARK: - CardModel
//struct CardModel: Identifiable, Codable {
//    var id: String
//    var uid: String
//    var name: String
//    var profession: String
//    var company: String
//    var category: String
//    var coordinate: CLLocationCoordinate2D
//
//    // Firestore doesn't natively handle CLLocationCoordinate2D, so we map it manually
//    enum CodingKeys: String, CodingKey {
//        case id, uid, name, profession, company, category
//        case latitude, longitude
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decode(String.self, forKey: .id)
//        uid = try container.decode(String.self, forKey: .uid)
//        name = try container.decode(String.self, forKey: .name)
//        profession = try container.decode(String.self, forKey: .profession)
//        company = try container.decode(String.self, forKey: .company)
//        category = try container.decode(String.self, forKey: .category)
//        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
//        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
//        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(uid, forKey: .uid)
//        try container.encode(name, forKey: .name)
//        try container.encode(profession, forKey: .profession)
//        try container.encode(company, forKey: .company)
//        try container.encode(category, forKey: .category)
//        try container.encode(coordinate.latitude, forKey: .latitude)
//        try container.encode(coordinate.longitude, forKey: .longitude)
//    }
//}
//
//// MARK: - LocationManager
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    @Published var currentLocation: CLLocation?
//    private var locationManager = CLLocationManager()
//
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        currentLocation = locations.last
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Failed to find user's location: \(error.localizedDescription)")
//    }
//}
//
//// MARK: - MapViewModel
//class MapViewModel: ObservableObject {
//    @Published var userCards: [CardModel] = []
//    @Published var filteredUserCards: [CardModel] = []
//    @Published var searchText = ""
//    @Published var selectedCategory: String = "All Cards"
//    @Published var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//    )
//    @Published var followUserLocation = false
//
//    private var cancellables = Set<AnyCancellable>()
//    private let db = Firestore.firestore()
//
//    init() {
//        fetchUserCards()
//        setupSearchAndFilter()
//    }
//
//    private func setupSearchAndFilter() {
//        Publishers.CombineLatest($searchText, $selectedCategory)
//            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
//            .map { [weak self] (searchText, category) in
//                self?.filterUserCards(searchText: searchText, category: category) ?? []
//            }
//            .assign(to: &$filteredUserCards)
//    }
//
//    func fetchUserCards() {
//        db.collection("UserDatabase").getDocuments { [weak self] snapshot, error in
//            if let error = error {
//                print("Error fetching user cards: \(error.localizedDescription)")
//                return
//            }
//            guard let documents = snapshot?.documents else { return }
//            self?.userCards = documents.compactMap { try? $0.data(as: CardModel.self) }
//            self?.filteredUserCards = self?.userCards ?? []
//        }
//    }
//
//    private func filterUserCards(searchText: String, category: String) -> [CardModel] {
//        userCards.filter { card in
//            let matchesSearchText = searchText.isEmpty ||
//                card.name.localizedCaseInsensitiveContains(searchText) ||
//                card.profession.localizedCaseInsensitiveContains(searchText) ||
//                card.company.localizedCaseInsensitiveContains(searchText)
//            let matchesCategory = category == "All Cards" || card.category == category
//            return matchesSearchText && matchesCategory
//        }
//    }
//
//    func categoryColor(for category: String) -> Color {
//        // Example logic for assigning colors
//        switch category {
//        case "Tech": return .blue
//        case "Art": return .purple
//        case "Business": return .green
//        default: return .gray
//        }
//    }
//
//    func selectCategory(_ category: String) {
//        selectedCategory = category
//    }
//}
//
//// MARK: - MapView
//struct MapView: View {
//    @StateObject private var viewModel = MapViewModel()
//    @StateObject private var locationManager = LocationManager()
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                ZStack(alignment: .bottomTrailing) {
//                    Map(coordinateRegion: $viewModel.region,
//                        showsUserLocation: true,
//                        annotationItems: viewModel.filteredUserCards) { card in
//                        MapAnnotation(coordinate: card.coordinate) {
//                            VStack {
//                                Circle()
//                                    .fill(viewModel.categoryColor(for: card.category))
//                                    .frame(width: 30, height: 30)
//                                    .overlay(
//                                        Text(String(card.name.prefix(1)))
//                                            .foregroundColor(.white)
//                                            .font(.headline)
//                                    )
//                            }
//                        }
//                    }
//
//                    VStack(spacing: 20) {
//                        Button(action: {
//                            viewModel.region.span.latitudeDelta /= 2
//                            viewModel.region.span.longitudeDelta /= 2
//                        }) {
//                            Image(systemName: "plus.circle.fill")
//                                .resizable()
//                                .frame(width: 40, height: 40)
//                        }
//
//                        Button(action: {
//                            viewModel.region.span.latitudeDelta *= 2
//                            viewModel.region.span.longitudeDelta *= 2
//                        }) {
//                            Image(systemName: "minus.circle.fill")
//                                .resizable()
//                                .frame(width: 40, height: 40)
//                        }
//
//                        Button(action: {
//                            viewModel.followUserLocation.toggle()
//                            if viewModel.followUserLocation, let userLocation = locationManager.currentLocation {
//                                viewModel.region.center = userLocation.coordinate
//                            }
//                        }) {
//                            Image(systemName: viewModel.followUserLocation ? "location.fill" : "location")
//                                .resizable()
//                                .frame(width: 40, height: 40)
//                        }
//                    }
//                    .padding()
//                }
//
//                TextField("Search...", text: $viewModel.searchText)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(10)
//                    .padding(.horizontal)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack {
//                        ForEach(["All Cards", "Tech", "Art", "Business"], id: \.self) { category in
//                            Button(action: {
//                                viewModel.selectCategory(category)
//                            }) {
//                                Text(category)
//                                    .padding()
//                                    .background(viewModel.selectedCategory == category ? Color.blue : Color.gray)
//                                    .cornerRadius(10)
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//}
//
//// MARK: - Preview
//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapView()
//    }
//}
