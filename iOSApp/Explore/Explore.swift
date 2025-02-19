import SwiftUI
import MapKit
import CoreLocation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct UserAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct UserDetails: Identifiable {
    let id: String?
    let firstName: String
    let designation: String
    let company: String
    let phoneNumber: String
    let email: String
}

struct UserDetailsCategory: Identifiable, Hashable {
    let id = UUID()
    let firstName: String
    let designation: String
    let company: String
    let phoneNumber: String
    let email: String
    let latitude: Double
    let longitude: Double
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: UserDetailsCategory, rhs: UserDetailsCategory) -> Bool {
        return lhs.id == rhs.id
    }
}


class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults = [MyAnnotation]()
}

struct MyAnnotation: Identifiable {
    let id : String
    var coordinate: CLLocationCoordinate2D
    var userDetails: UserDetails
}

struct CategoryDetailsView: View {
    let category: String

    var body: some View {
        VStack {
            Text("Details for Category: \(category)")
                .font(.title)
                .padding()

            Spacer()

            Button("Close") {
            }
            .padding()
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
            .foregroundColor(.black)
            .padding()
        }
    }
}
// MARK: - Search Bar Component
struct MapSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            TextField("Search names, companies...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .tint(.blue)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}
struct CustomAnnotationView: View {
    var userDetails: UserDetails
    var viewedUserUID: String?
    var onSaveCard: (() -> Void)?
    @State private var isUIDPresent: Bool = false
    @State private var showAlert = false
    @State private var showDetails = false
    @State private var cardColor: Color = .black // Add state for card color
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            if showDetails {
                VStack(spacing: 15) {
                    Text(userDetails.firstName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(userDetails.designation)
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text(userDetails.company)
                        .font(.title3)
                        .foregroundColor(.gray)

                    if !isUIDPresent {
                        Button("Save Card") {
                            onSaveCard?()
                            showAlert = true
                        }
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.black)
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(20)
                .onTapGesture {
                    withAnimation {
                        showDetails.toggle()
                    }
                }
                .frame(height: 200)
                .offset(y: -100)
            }

            Image(systemName: "rectangle.fill")
                .foregroundColor(cardColor) // Use the dynamic card color
                .frame(width: 80, height: 120)
                .onTapGesture {
                    withAnimation {
                        showDetails.toggle()
                    }
                }
                .zIndex(1)
        }
        .onAppear {
            checkUIDPresence(viewedUID: viewedUserUID)
            setupColorListener() // Add real-time color listener
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text("Card Successfully Saved"), dismissButton: .default(Text("OK")))
        }
    }

    // Add function to set up real-time color listener
    private func setupColorListener() {
        guard let uid = viewedUserUID else { return }
        
        let userRef = db.collection("UserDatabase").document(uid)
        userRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let colorString = document.data()?["cardColor"] as? String {
                switch colorString {
                case "black": cardColor = .black
                case "blue": cardColor = .blue
                case "red": cardColor = .red
                case "green": cardColor = .green
                case "purple": cardColor = .purple
                case "orange": cardColor = .orange
                default: cardColor = .black
                }
            }
        }
    }

    private func checkUIDPresence(viewedUID: String?) {
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

            if let document = document, document.exists {
                let data = document.data()
                if let scannedUIDs = data?["scannedUIDs"] as? [String] {
                    if scannedUIDs.contains(where: { $0 == viewedUID }) {
                        isUIDPresent = true
                    }
                }
            }
        }
    }
}


struct NextView: View {
    // MARK: - Properties
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var showSearchResults = true
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var filteredAnnotations: [MyAnnotation] = []
    @State private var searchCategory = "All Cards"
    @State private var selectedProfession = ""
    @State private var showCategorySheet = false
    @State private var followUserLocation = true
    private let db = Firestore.firestore()
    let categories: [String: [String]] = [
        "All Cards": [],
        "Tech": ["Tech",
            "SDE",
            "Software Engineer",
            "Data Scientist",
            "Network Administrator",
            "Web Developer",
            "Lead IOS Developer",
            "IOS Developer",
            "iOS Developer",
            "UX/UI Designer",
            "Database Administrator",
            "DevOps Engineer",
            "IT Consultant",
            "System Analyst",
            "Cybersecurity Analyst",
            "Mobile App Developer",
            "AI/Machine Learning Engineer",
            "Game Developer",
            "QA Tester",
            "Cloud Solutions Architect",
            "Tech Support Specialist",
            "Technical Writer",
            "Embedded Systems Engineer",
            "Network Engineer",
            "Full Stack Developer",
            "Tester"
        ],
        "Doctor": ["Doctor",
            "General Practitioner",
            "Cardiologist",
            "Dentist",
            "Orthopedic Surgeon",
            "Pediatrician",
            "Ophthalmologist",
            "Psychiatrist",
            "Neurologist",
            "Obstetrician/Gynecologist",
            "Anesthesiologist",
            "Radiologist",
            "Pathologist",
            "General Surgeon",
            "Emergency Medicine Physician",
            "Family Medicine Physician",
            "Urologist",
            "Dermatologist",
            "Oncologist",
            "Endocrinologist",
            "Nephrologist"
        ],
        "Education": ["Education",
            "Student",
            "Teacher",
            "Professor"
        ],

        "Utility": ["Utility",
            "Plumber",
            "Electrician",
            "HVAC Technician",
            "Carpenter",
            "Mechanic",
            "Locksmith",
            "Landscaper",
            "Painter",
            "Pool Cleaner",
            "Appliance Repair Technician",
            "Roofing Contractor",
            "Pest Control Technician",
            "Septic Tank Services",
            "Glass Installer",
            "Welder",
            "Solar Panel Installer",
            "Elevator Mechanic",
            "Building Inspector",
            "Fire Alarm Technician",
            "Masonry Worker"
        ],
        "Entertainment": ["Entertainment",
            "Actor",
            "Musician",
            "Video Game Developer",
            "Film Director",
            "Cinematographer",
            "Sound Engineer",
            "Choreographer",
            "Costume Designer",
            "Makeup Artist",
            "Stunt Performer",
            "Film Editor",
            "Set Designer",
            "Casting Director",
            "Storyboard Artist",
            "Location Manager",
            "Voice Actor",
            "Script Supervisor",
            "Film Producer",
            "Entertainment Lawyer",
            "Talent Agent"
        ],
        "Artist": ["Artist",
            "Painter",
            "Sculptor",
            "Graphic Designer",
            "Photographer",
            "Illustrator",
            "Printmaker",
            "Ceramic Artist",
            "Textile Designer",
            "Jewelry Designer",
            "Glassblower",
            "Digital Artist",
            "Street Artist",
            "Installation Artist",
            "Muralist",
            "Collage Artist",
            "Comic Book Artist",
            "Cartoonist",
            "Conceptual Artist",
            "Mixed Media Artist",
            "Tattoo Artist"
        ],
        "Management": ["Management",
            "Project Manager",
            "HR Manager",
            "Financial Analyst",
            "Marketing Manager",
            "Operations Manager",
            "Product Manager",
            "Sales Manager",
            "Supply Chain Manager",
            "Business Analyst",
            "Quality Assurance Manager",
            "Risk Manager",
            "IT Manager",
            "Event Planner",
            "Public Relations Manager",
            "Brand Manager",
            "Facilities Manager",
            "Customer Success Manager",
            "Research and Development Manager",
            "Training and Development Manager",
            "Legal Operations Manager"
        ],
        "Others": []
    ]
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Map View
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: .constant(followUserLocation ? .follow : .none),
                annotationItems: filteredAnnotations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    CustomAnnotationView(
                        userDetails: location.userDetails,
                        viewedUserUID: location.userDetails.id,
                        onSaveCard: { saveCard(for: location.userDetails.id ?? "") }
                    )
                }
            }
            .mapControls {
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea(edges: .top)
            
            // Search and Controls Overlay
            VStack(spacing: 0) {
                MapSearchBar(text: $searchViewModel.searchText)
                                   .padding(.horizontal)
                                   .padding(.top)
                                   .onChange(of: searchViewModel.searchText) { newValue in
                                       filterAnnotations(for: newValue, inCategory: searchCategory)
                                       showSearchResults = !newValue.isEmpty
                                   }
                               
                               // Updated Search Results
                               if !searchViewModel.searchText.isEmpty && showSearchResults {
                                   searchResults
                                       .background(
                                           RoundedRectangle(cornerRadius: 15)
                                               .fill(Color(UIColor.systemBackground).opacity(0.98))
                                               .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                       )
                                       .padding(.horizontal)
                               }
                
                Spacer()
                Spacer()
                // Map Controls
                mapControls
                    .padding(.bottom, 20)
                
                // Category Sheet Button
                Button(action: { showCategorySheet = true }) {
                    Text("Categories")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .cornerRadius(15)
                }
                .padding()
                
                
            }
        }
        .sheet(isPresented: $showCategorySheet) {
            CategorySheetView(
                selectedCategory: $searchCategory,
                onCategorySelected: { category in
                    filterAnnotations(for: searchViewModel.searchText, inCategory: category)
                    showCategorySheet = false
                }
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            locationManager.requestLocationPermission()
            if let location = locationManager.userLocation {
                region.center = location
            }
            fetchUserLocations()
        }
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        TextField("🔍    Search names, companies, and professions", text: $searchViewModel.searchText)
            .padding(12)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal, 16)
            .onChange(of: searchViewModel.searchText) { newValue in
                filterAnnotations(for: newValue, inCategory: searchCategory)
                showSearchResults = !newValue.isEmpty // Show results only if search text is not empty
            }
    }

    private var searchResults: some View {
        if showSearchResults {
            return AnyView(
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(filteredAnnotations) { annotation in
                            Button {
                                withAnimation {
                                    region.center = annotation.coordinate // Focus on location
                                    showSearchResults = false // Dismiss search results
                                    searchViewModel.searchText = "" // Clear search text
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(annotation.userDetails.firstName)
                                        .font(.headline)
                                    Text(annotation.userDetails.designation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 200)
                .background(.ultraThinMaterial)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private var mapControls: some View {
        HStack {
            Spacer()
            VStack(spacing: 20) {
                // Zoom controls
                Button { region.span.latitudeDelta /= 2 } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                
                Button { region.span.latitudeDelta *= 2 } label: {
                    Image(systemName: "minus.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                
                // Location tracking
                Button {
                    followUserLocation.toggle()
                    if followUserLocation, let location = locationManager.userLocation {
                        region.center = location
                    }
                } label: {
                    Image(systemName: followUserLocation ? "location.circle.fill" : "location.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(followUserLocation ? .black : .black)
                }
            }
            .foregroundColor(.black)
            .padding()
        }
    }
    private func saveCard(for uid: String) {
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
    private func filterAnnotations(for searchText: String, inCategory category: String) {
        if searchText.isEmpty && selectedProfession.isEmpty {
            filteredAnnotations = searchViewModel.searchResults.filter { annotation in
                let categoryMatch = category == "All Cards" || categories[category]?.contains(annotation.userDetails.designation) == true
                return categoryMatch
            }
        } else {
            filteredAnnotations = searchViewModel.searchResults.filter { annotation in
                let searchTextMatch = searchText.isEmpty ||
                    annotation.userDetails.firstName.localizedCaseInsensitiveContains(searchText) ||
                    annotation.userDetails.designation.localizedCaseInsensitiveContains(searchText) ||
                    annotation.userDetails.company.localizedCaseInsensitiveContains(searchText)

                let professionMatch = selectedProfession.isEmpty || categories[category]?.contains(annotation.userDetails.designation) == true

                let categoryMatch = category == "All Cards" || categories[category]?.contains(annotation.userDetails.designation) == true

                return searchTextMatch && professionMatch && categoryMatch
            }
        }
        if let firstResult = filteredAnnotations.first {
            region.center = firstResult.coordinate
        }
    }

    
    private func fetchUserLocations() {
        let db = Firestore.firestore()
        
        db.collection("UserDatabase").getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            for document in documents {
                guard let latitude = document["latitude"] as? Double,
                      let longitude = document["longitude"] as? Double,
                      let profession = document["profession"] as? String,
                      let name = document["name"] as? String,
                      let company = document["company"] as? String,
                      let phoneNumber = document["phoneNumber"] as? String,
                      let userID = document.documentID as? String else {
                    print("Missing or invalid data for a user")
                    continue
                }

                db.collection("Location").document(userID).getDocument { (locationDocument, locationError) in
                    guard let locationData = locationDocument?.data(),
                          let publicLocation = locationData["PublicLocation"] as? String else {
                        print("Error fetching PublicLocation for user: \(userID)")
                        return
                    }

                    if publicLocation == "ON" {
                        if let email = document["email"] as? String,
                               let userLatitude = document["latitude"] as? Double,                                let userLongitude = document["longitude"] as? Double {
                            let userDetails = UserDetails(id: userID, firstName: name, designation: profession, company: company, phoneNumber: phoneNumber, email: email)
                            let userDetailsCategory = UserDetailsCategory(firstName: name, designation: profession, company: company, phoneNumber: phoneNumber, email: email, latitude: userLatitude, longitude: userLongitude)
                            let annotation = MyAnnotation(id: userID, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), userDetails: userDetails)
                            DispatchQueue.main.async {
                                searchViewModel.searchResults.append(annotation)
                                filteredAnnotations = searchViewModel.searchResults
                            }
                        }
                    }
                }
            }
        }
    }
    
}

    struct NextView_Previews: PreviewProvider {
        static var previews: some View {
            NextView()
        }
    }

struct CategorySheetView: View {
    @Binding var selectedCategory: String
    let onCategorySelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    let categories = [
        "All Cards", "Tech", "Doctor", "Education",
        "Utility", "Entertainment", "Artist", "Management", "Others"
    ]
    
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
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            onCategorySelected(category)
                        } label: {
                            VStack {
                                Image(systemName: categoryIcons[category] ?? "questionmark.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                Text(category)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 90, height: 90)
                            .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
