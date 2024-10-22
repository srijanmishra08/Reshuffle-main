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
struct CustomAnnotationView: View {
    var userDetails: UserDetails
    var viewedUserUID: String?
    var onSaveCard: (() -> Void)?
    @State private var isUIDPresent: Bool = false
    @State private var showAlert = false
    @State private var showDetails = false
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
                .foregroundColor(.black)
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
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text("Card Successfully Saved"), dismissButton: .default(Text("OK")))
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
    @State private var viewedUserUID: String?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isCardListActive = false
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var filteredAnnotations: [MyAnnotation] = []
    @State private var locationManager = CLLocationManager()
    @State private var dragOffset: CGSize = .zero
    @State private var searchCategory = "All Cards"
    @State private var selectedProfession = ""
    @State private var isSearching = false

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
    let categories: [String: [String]] = [
        "All Cards": [],
        "Tech": [
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
        "Doctor": [
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
        "Education": [
            "Student",
            "Teacher",
            "Professor"
        ],

        "Utility": [
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
        "Entertainment": [
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
        "Artist": [
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
        "Management": [
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
    @State private var isPopoverPresented = false
    @State private var popoverContent: AnyView?
    @State private var followUserLocation = true
    
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .bottomTrailing) {
                    Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .constant(followUserLocation ? .follow : .none), annotationItems: filteredAnnotations) { location in
                        MapAnnotation(coordinate: location.coordinate) {
                            CustomAnnotationView(userDetails: location.userDetails,
                                                 viewedUserUID: location.userDetails.id,
                                                 onSaveCard: {
                                saveCard(for: location.userDetails.id ?? "")
                            })
                            .onTapGesture {
                            }
                            .onAppear {
                                        loadInitialAnnotations()
                                    }
                        }
                    }
                    .mapControls{
                        MapCompass()
                        MapPitchToggle()
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.7)
                    .mapStyle(.standard)
                    .onAppear {
                        locationManager.requestWhenInUseAuthorization()
                        if let userLocation = locationManager.location?.coordinate {
                            region.center = userLocation
                        }
                        fetchUserLocations()
                    }
                    
                    VStack {
                        TextField("🔍    Search names, companies, and professions", text: $searchViewModel.searchText)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                            .padding(.top, 150)
                            .padding(.bottom, 10)
                            .onChange(of: searchViewModel.searchText) { searchText in
                                filterAnnotations(for: searchText, inCategory: searchCategory)
                            }
                        
                        if isSearching {
                            Picker("Profession", selection: $selectedProfession) {
                                ForEach(categories[searchCategory] ?? [], id: \.self) { profession in
                                    Text(profession)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: searchViewModel.searchText) { searchText in
                                filterAnnotations(for: searchText, inCategory: searchCategory)
                            }
                            .onChange(of: selectedProfession) { _ in
                                filterAnnotations(for: searchViewModel.searchText, inCategory: searchCategory)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        }
                        
                        Spacer()
                    }
                    
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            region.span.latitudeDelta /= 2
                            region.span.longitudeDelta /= 2
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black.opacity(0.8))
                        }
                        
                        Button(action: {
                            region.span.latitudeDelta *= 2
                            region.span.longitudeDelta *= 2
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black.opacity(0.8))
                        }
                        
                        Button(action: {
                            followUserLocation.toggle()
                            
                            if followUserLocation, let userLocation = locationManager.location?.coordinate {
                                region.center = userLocation
                            }
                        }) {
                            Image(systemName: followUserLocation ? "location.fill" : "location")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(followUserLocation ? .blue : .black.opacity(0.8))
                        }
                    }
                    .padding()
                }
                .padding(.bottom, 5)
                
                VStack {
                    Text("Categories")
                        .font(.title.bold())
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            Button(action: {
                                showUserDetailsCategory(for: key)
                            }) {
                                VStack {
                                    Image(systemName: categoryIcons[key] ?? "questionmark.circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 25)
                                    Text(key)
                                        .font(.body)
                                        .padding(.top, 5)
                                }
                                .frame(width: 75, height: 60)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(15)
                                .foregroundColor(.black)
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                }
                
                Spacer()
                
                NavigationLink(
                    destination: CardListView(),
                    isActive: $isCardListActive
                ) {
                    EmptyView()
                }
                .hidden()
                
                Button("Saved Cards") {
                    isCardListActive = true
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .foregroundColor(.black)
                .padding(.top, 10)
                .padding(.horizontal)
                .padding(.bottom, 80)
                .popover(isPresented: $isPopoverPresented) {
                    popoverContent
                }
            }
            .accentColor(.black)
            .padding(.bottom, 80)
        }
    }
    private func loadInitialAnnotations() {
        
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

//                let professionMatch = selectedProfession.isEmpty || categories[category]?.contains(annotation.userDetails.designation) == true
//
//                let categoryMatch = category == "All Cards" || categories[category]?.contains(annotation.userDetails.designation) == true

                return searchTextMatch /*&& professionMatch && categoryMatch*/
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
    
    private func showUserDetailsCategory(for category: String) {
            let db = Firestore.firestore()
            
        if category == "All Cards" {
                    db.collection("UserDatabase").getDocuments { (querySnapshot, error) in
                        guard let documents = querySnapshot?.documents else {
                            print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                            return
                        }
                        
                        let allUsers: [UserDetailsCategory] = documents.map { document in
                            guard let firstName = document["name"] as? String,
                                  let designation = document["profession"] as? String,
                                  let company = document["company"] as? String,
                                  let phoneNumber = document["phoneNumber"] as? String,
                                  let email = document["email"] as? String,
                                  let latitude = document["latitude"] as? Double,
                                  let longitude = document["longitude"] as? Double
                            else {
                                print("Missing or invalid data for a user")
                            
                                return nil
                            }
                            
                            return UserDetailsCategory(firstName: firstName, designation: designation, company: company, phoneNumber: phoneNumber, email: email, latitude: latitude, longitude: longitude)
                        }.compactMap { $0 }
                        
                        let categorizedUsers = categorizeUsersCategory(allUsers, for: category)
                        presentUserDetailsPopupCategory(users: categorizedUsers)
                    }
                } else {
                    db.collection("UserDatabase").whereField("profession", isNotEqualTo: "").getDocuments { (querySnapshot, error) in
                        guard let documents = querySnapshot?.documents else {
                            print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                            return
                        }
                        if let userDocument = documents.first {
                                        if let latitude = userDocument["latitude"] as? Double,
                                           let longitude = userDocument["longitude"] as? Double {
                                            let selectedRegion = MKCoordinateRegion(
                                                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                                            )
                                            self.region = selectedRegion
                                        }
                                    }
                        
                        let filteredUsers: [UserDetailsCategory] = documents.compactMap { document in
                            guard let firstName = document["name"] as? String,
                                  let designation = document["profession"] as? String,
                                  let company = document["company"] as? String,
                                  let phoneNumber = document["phoneNumber"] as? String,
                                  let email = document["email"] as? String,
                                  let latitude = document["latitude"] as? Double,
                                  let longitude = document["longitude"] as? Double
                            else {
                                print("Missing or invalid data for a user")
                                
                                return nil
                            }
                            
                            return UserDetailsCategory(firstName: firstName, designation: designation, company: company, phoneNumber: phoneNumber, email: email, latitude: latitude, longitude: longitude)
                        }.compactMap { $0 }
                        
                        let categorizedUsers = categorizeUsersCategory(filteredUsers, for: category)
                        presentUserDetailsPopupCategory(users: categorizedUsers)
                    }
                }
            }

    private func presentUserDetailsPopupCategory(users: [UserDetailsCategory]) {
        guard let userLocation = locationManager.location else {
            print("User location not available")
            return
        }

        var usersWithDistance: [(UserDetailsCategory, Double, String)] = []
        for user in users {
            let userCoordinate = CLLocation(latitude: user.latitude, longitude: user.longitude)
            let distance = userLocation.distance(from: userCoordinate)
            
            var distanceString: String
            if distance < 1000 {
                distanceString = "\(Int(distance)) meters"
            } else {
                let distanceInKm = distance / 1000
                distanceString = String(format: "%.2f", distanceInKm) + " kms"
            }
            
            usersWithDistance.append((user, distance, distanceString))
        }

        let popupContent: some View = ScrollView {
            VStack(alignment: .leading) {
                ForEach(usersWithDistance, id: \.0) { user, distance, distanceString in
                    Button(action: {
                        let userCoordinate = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
                        updateMapRegion(to: userCoordinate)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(user.firstName)")
                                    .font(.headline)
                                Text("\(user.designation), \(user.company)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(distanceString) away")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.black)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.vertical, 5)
                    
                   Divider().background(Color.gray)
                }
            }
            .padding()
        }

        popoverContent = AnyView(popupContent)
        isPopoverPresented = true
    }

    private func updateMapRegion(to coordinate: CLLocationCoordinate2D) {
        withAnimation {
            region.center = coordinate
        }
    }




    private func categorizeUsersCategory(_ users: [UserDetailsCategory], for category: String) -> [UserDetailsCategory] {
             if category == "All Cards" {
                         return users
                     }
             let categoryProfessions: Set<String>

             switch category {
             case "Tech":
                 categoryProfessions = Set([
                     "SDE", "Software Engineer", "Data Scientist", "Network Administrator","Lead IOS Developer",
                     "IOS Developer",
                     "iOS Developer",
                     "Web Developer", "UX/UI Designer", "Database Administrator", "DevOps Engineer",
                     "IT Consultant", "System Analyst", "Cybersecurity Analyst", "Mobile App Developer",
                     "AI/Machine Learning Engineer", "Game Developer", "QA Tester", "Cloud Solutions Architect",
                     "Tech Support Specialist", "Technical Writer", "Embedded Systems Engineer",
                     "Network Engineer", "Full Stack Developer", "Tester"
                 ])
             case "Doctor":
                 categoryProfessions = Set([
                     "General Practitioner", "Cardiologist", "Dentist", "Orthopedic Surgeon",
                     "Pediatrician", "Ophthalmologist", "Psychiatrist", "Neurologist",
                     "Obstetrician/Gynecologist", "Anesthesiologist", "Radiologist", "Pathologist",
                     "General Surgeon", "Emergency Medicine Physician", "Family Medicine Physician",
                     "Urologist", "Dermatologist", "Oncologist", "Endocrinologist", "Nephrologist"
                 ])
             case "Utility":
                 categoryProfessions = Set([
                     "Plumber", "Electrician", "HVAC Technician", "Carpenter", "Mechanic",
                     "Locksmith", "Landscaper", "Painter", "Pool Cleaner", "Appliance Repair Technician",
                     "Roofing Contractor", "Pest Control Technician", "Septic Tank Services", "Glass Installer",
                     "Welder", "Solar Panel Installer", "Elevator Mechanic", "Building Inspector",
                     "Fire Alarm Technician", "Masonry Worker"
                 ])
             case "Entertainment":
                 categoryProfessions = Set([
                     "Actor", "Musician", "Video Game Developer", "Film Director", "Cinematographer",
                     "Sound Engineer", "Choreographer", "Costume Designer", "Makeup Artist", "Stunt Performer",
                     "Film Editor", "Set Designer", "Casting Director", "Storyboard Artist", "Location Manager",
                     "Voice Actor", "Script Supervisor", "Film Producer", "Entertainment Lawyer", "Talent Agent"
                 ])
             case "Artist":
                 categoryProfessions = Set([
                     "Painter", "Sculptor", "Graphic Designer", "Photographer", "Illustrator",
                     "Printmaker", "Ceramic Artist", "Textile Designer", "Jewelry Designer", "Glassblower",
                     "Digital Artist", "Street Artist", "Installation Artist", "Muralist", "Collage Artist",
                     "Comic Book Artist", "Cartoonist", "Conceptual Artist", "Mixed Media Artist", "Tattoo Artist"
                 ])
             case "Education":
                 categoryProfessions = Set([
                     "Student","Teacher","Professor"
                 ])
             case "Management":
                 categoryProfessions = Set([
                     "Project Manager", "HR Manager", "Financial Analyst", "Marketing Manager",
                     "Operations Manager", "Product Manager", "Sales Manager", "Supply Chain Manager",
                     "Business Analyst", "Quality Assurance Manager", "Risk Manager", "IT Manager",
                     "Event Planner", "Public Relations Manager", "Brand Manager", "Facilities Manager",
                     "Customer Success Manager", "Research and Development Manager", "Training and Development Manager",
                     "Legal Operations Manager"
                 ])
             default:
                 return users.filter { !$0.designation.isEmpty }
             }

             return users.filter { categoryProfessions.contains($0.designation) }
         }

    private func showUserDetails(for category: String) {
            let db = Firestore.firestore()
            
            if category == "All Cards" {
                db.collection("UserDatabase").getDocuments { (querySnapshot, error) in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    let allUsers: [UserDetails] = documents.compactMap { document in
                        guard let firstName = document["name"] as? String,
                              let designation = document["profession"] as? String,
                              let company = document["company"] as? String,
                              let phoneNumber = document["phoneNumber"] as? String,
                              let email = document["email"] as? String else {
                            print("Missing or invalid data for a user")
                            return nil
                        }
                        
                        
                        let id = document["id"] as? String
                        
                        return UserDetails(id: id, firstName: firstName, designation: designation, company: company, phoneNumber: phoneNumber, email: email)
                    }
                    
                    let categorizedUsers = categorizeUsers(allUsers, for: category)
                    presentUserDetailsPopup(users: categorizedUsers)
                }
            } else {
                db.collection("UserDatabase").whereField("profession", isNotEqualTo: "").getDocuments { (querySnapshot, error) in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    let filteredUsers: [UserDetails] = documents.compactMap { document in
                        guard let firstName = document["name"] as? String,
                              let designation = document["profession"] as? String,
                              let company = document["company"] as? String,
                              let phoneNumber = document["phoneNumber"] as? String,
                              let email = document["email"] as? String else {
                            print("Missing or invalid data for a user")
                            return nil
                        }
                        let id = document["id"] as? String
                        
                        return UserDetails(id: id, firstName: firstName, designation: designation, company: company, phoneNumber: phoneNumber, email: email)
                    }
                    
                    
                    let categorizedUsers = categorizeUsers(filteredUsers, for: category)
                    presentUserDetailsPopup(users: categorizedUsers)
                }
            }
        }


    private func presentUserDetailsPopup(users: [UserDetails]) {
        let popupContent: some View = ScrollView {
            VStack(alignment: .leading) {
                ForEach(users) { user in
                    VStack(alignment: .leading) {
                        Text("\(user.firstName)")
                            .font(.headline)
                        Text("\(user.designation), \(user.company)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Divider()
                    }
                    .padding()
                }
            }
        }
       
        popoverContent = AnyView(popupContent)

        isPopoverPresented = true
    }


    private func categorizeUsers(_ users: [UserDetails], for category: String) -> [UserDetails] {
             if category == "All Cards" {
                         return users
                     }
             let categoryProfessions: Set<String>

             switch category {
             case "Tech":
                 categoryProfessions = Set([
                     "SDE", "Software Engineer", "Data Scientist", "Network Administrator","Lead IOS Developer",
                     "IOS Developer",
                     "iOS Developer",
                     "Web Developer", "UX/UI Designer", "Database Administrator", "DevOps Engineer",
                     "IT Consultant", "System Analyst", "Cybersecurity Analyst", "Mobile App Developer",
                     "AI/Machine Learning Engineer", "Game Developer", "QA Tester", "Cloud Solutions Architect",
                     "Tech Support Specialist", "Technical Writer", "Embedded Systems Engineer",
                     "Network Engineer", "Full Stack Developer", "Tester"
                 ])
             case "Doctor":
                 categoryProfessions = Set([
                     "General Practitioner", "Cardiologist", "Dentist", "Orthopedic Surgeon",
                     "Pediatrician", "Ophthalmologist", "Psychiatrist", "Neurologist",
                     "Obstetrician/Gynecologist", "Anesthesiologist", "Radiologist", "Pathologist",
                     "General Surgeon", "Emergency Medicine Physician", "Family Medicine Physician",
                     "Urologist", "Dermatologist", "Oncologist", "Endocrinologist", "Nephrologist"
                 ])
             case "Utility":
                 categoryProfessions = Set([
                     "Plumber", "Electrician", "HVAC Technician", "Carpenter", "Mechanic",
                     "Locksmith", "Landscaper", "Painter", "Pool Cleaner", "Appliance Repair Technician",
                     "Roofing Contractor", "Pest Control Technician", "Septic Tank Services", "Glass Installer",
                     "Welder", "Solar Panel Installer", "Elevator Mechanic", "Building Inspector",
                     "Fire Alarm Technician", "Masonry Worker"
                 ])
             case "Entertainment":
                 categoryProfessions = Set([
                     "Actor", "Musician", "Video Game Developer", "Film Director", "Cinematographer",
                     "Sound Engineer", "Choreographer", "Costume Designer", "Makeup Artist", "Stunt Performer",
                     "Film Editor", "Set Designer", "Casting Director", "Storyboard Artist", "Location Manager",
                     "Voice Actor", "Script Supervisor", "Film Producer", "Entertainment Lawyer", "Talent Agent"
                 ])
             case "Artist":
                 categoryProfessions = Set([
                     "Painter", "Sculptor", "Graphic Designer", "Photographer", "Illustrator",
                     "Printmaker", "Ceramic Artist", "Textile Designer", "Jewelry Designer", "Glassblower",
                     "Digital Artist", "Street Artist", "Installation Artist", "Muralist", "Collage Artist",
                     "Comic Book Artist", "Cartoonist", "Conceptual Artist", "Mixed Media Artist", "Tattoo Artist"
                 ])
             case "Education":
                 categoryProfessions = Set([
                     "Student","Teacher","Professor"
                 ])
             case "Management":
                 categoryProfessions = Set([
                     "Project Manager", "HR Manager", "Financial Analyst", "Marketing Manager",
                     "Operations Manager", "Product Manager", "Sales Manager", "Supply Chain Manager",
                     "Business Analyst", "Quality Assurance Manager", "Risk Manager", "IT Manager",
                     "Event Planner", "Public Relations Manager", "Brand Manager", "Facilities Manager",
                     "Customer Success Manager", "Research and Development Manager", "Training and Development Manager",
                     "Legal Operations Manager"
                 ])
             default:
                 return users.filter { !$0.designation.isEmpty }
             }

             return users.filter { categoryProfessions.contains($0.designation) }
         }
     }

    struct NextView_Previews: PreviewProvider {
        static var previews: some View {
            NextView()
        }
    }
