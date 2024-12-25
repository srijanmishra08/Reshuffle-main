import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import Firebase
import AuthenticationServices
import GoogleSignIn
import Combine
import MapKit

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

class UserData: ObservableObject {
    let id = UUID()
    @Published var someData: String = "Example Data"
    @Published var user: BusinessCard = BusinessCard(id: UUID(), name: "", profession: "", email: "", company: "", role: "", description: "", phoneNumber: "", whatsapp: "", address: "", website: "", linkedIn: "", instagram: "", xHandle: "", region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                                                     trackingMode: .follow)
    static let shared = UserData()
}
struct CoordinateWrapper: Equatable {
    var coordinate: CLLocationCoordinate2D

    static func == (lhs: CoordinateWrapper, rhs: CoordinateWrapper) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct BusinessCard{
    var id: UUID
    var name: String
    var profession: String
    var email: String
    var company: String
    var role: String
    var description: String
    var phoneNumber: String
    var whatsapp: String
    var address: String
    var website: String
    var linkedIn: String
    var instagram: String
    var xHandle: String
    var region: MKCoordinateRegion
    var trackingMode: MapUserTrackingMode
    var cardColor: UIColor = UIColor(red: 36/255.0, green: 143/255.0, blue: 152/255.0, alpha: 1.0)
    
}
struct Onboarding: View {
    @ObservedObject var userData: UserData
    @State private var user: BusinessCard = BusinessCard(id: UUID(), name: "", profession: "", email: "", company: "", role: "", description: "", phoneNumber: "", whatsapp: "", address: "", website: "", linkedIn: "", instagram: "", xHandle: "", region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                                                         trackingMode: .follow)
    @StateObject private var locationManager = LocationManager()
    @State private var isGetStartedActive = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image("Onboarding")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .foregroundColor(.green)

                Text("Hi there!")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                Text("Let’s create your first Reshuffle card! ")
                    .font(.title3)
                    .foregroundColor(.black)

                Image("Reshufflelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 80)
                    .foregroundColor(.green)
                    .padding()

                Button(action: {
                    locationManager.requestLocationPermission()

                    isGetStartedActive = true
                }) {
                    Text("Get started!")
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 150, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black)
                        )
                }
                .fullScreenCover(isPresented: $isGetStartedActive) {
                    SecondView(user: $user)
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear {
                locationManager.requestLocationPermission()
            }
        }
    }
}

struct SecondView: View {
    @State private var name: String = ""
    @State private var emailid: String = ""
    @State private var isNextButtonDisabled = true
    @Binding var user: BusinessCard
    let categoryIcons: [String: String] = [
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
        "Tech": [ "SDE", "Software Engineer", "Data Scientist", "Network Administrator", "Web Developer", "Lead IOS Developer", "IOS Developer", "iOS Developer", "UX/UI Designer", "Database Administrator", "DevOps Engineer", "IT Consultant", "System Analyst", "Cybersecurity Analyst", "Mobile App Developer", "AI/Machine Learning Engineer", "Game Developer", "QA Tester", "Cloud Solutions Architect", "Tech Support Specialist", "Technical Writer", "Embedded Systems Engineer", "Network Engineer", "Full Stack Developer", "Tester"],
        "Doctor": [ "General Practitioner", "Cardiologist", "Dentist", "Orthopedic Surgeon", "Pediatrician", "Ophthalmologist", "Psychiatrist", "Neurologist", "Obstetrician/Gynecologist", "Anesthesiologist", "Radiologist", "Pathologist", "General Surgeon", "Emergency Medicine Physician", "Family Medicine Physician", "Urologist", "Dermatologist", "Oncologist", "Endocrinologist", "Nephrologist"],
        "Education": [ "Student", "Teacher", "Professor"],
        "Utility": [ "Plumber", "Electrician", "HVAC Technician", "Carpenter", "Mechanic", "Locksmith", "Landscaper", "Painter", "Pool Cleaner", "Appliance Repair Technician", "Roofing Contractor", "Pest Control Technician", "Septic Tank Services", "Glass Installer", "Welder", "Solar Panel Installer", "Elevator Mechanic", "Building Inspector", "Fire Alarm Technician", "Masonry Worker"],
        "Entertainment": [ "Actor", "Musician", "Video Game Developer", "Film Director", "Cinematographer", "Sound Engineer", "Choreographer", "Costume Designer", "Makeup Artist", "Stunt Performer", "Film Editor", "Set Designer", "Casting Director", "Storyboard Artist", "Location Manager", "Voice Actor", "Script Supervisor", "Film Producer", "Entertainment Lawyer", "Talent Agent"],
        "Artist": [ "Painter", "Sculptor", "Graphic Designer", "Photographer", "Illustrator", "Printmaker", "Ceramic Artist", "Textile Designer", "Jewelry Designer", "Glassblower", "Digital Artist", "Street Artist", "Installation Artist", "Muralist", "Collage Artist", "Comic Book Artist", "Cartoonist", "Conceptual Artist", "Mixed Media Artist", "Tattoo Artist"],
        "Management": [ "Project Manager", "HR Manager", "Financial Analyst", "Marketing Manager", "Operations Manager", "Product Manager", "Sales Manager", "Supply Chain Manager", "Business Analyst", "Quality Assurance Manager", "Risk Manager", "IT Manager", "Event Planner", "Public Relations Manager", "Brand Manager", "Facilities Manager", "Customer Success Manager", "Research and Development Manager", "Training and Development Manager", "Legal Operations Manager"],
        "Others": []
    ]

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("Let's get started with the Basic Details !")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Spacer()

                TextField("Your name", text: $name)
                    .padding()
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .onChange(of: name) { newName in
                        user.name = newName
                        updateNextButtonState()
                    }
                
                TextField("Your Email Id", text: $emailid)
                    .padding()
                    .autocapitalization(.none)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .onChange(of: emailid) { newEmail in
                        user.email = newEmail
                        updateNextButtonState()
                    }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            Button(action: {
                                user.profession = key
                                updateNextButtonState()
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
                                .background(user.profession == key ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.3))
                                .cornerRadius(15)
                                .foregroundColor(.black)
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    user.name = name
                    user.email = emailid
                }) {
                    NavigationLink(destination: SeventhView(user: $user, name: name).navigationBarBackButtonHidden(true)) {
                        Text("Next")
                    }
                    .disabled(isNextButtonDisabled)
                }
                
                Spacer()
                Spacer()
                
                Image("Reshufflelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 80)
                    .foregroundColor(.green)
                    .padding()
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                updateNextButtonState()
            }
        }
    }
    
    private func updateNextButtonState() {
        isNextButtonDisabled = name.isEmpty || emailid.isEmpty || user.profession.isEmpty
    }
}

import SwiftUI
import MapKit

struct OfficeLocationView: View {
    struct MapPinItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapRegion: MKCoordinateRegion?
    @Binding var user: BusinessCard
    @Environment(\.presentationMode) var presentationMode
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Working Location")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Search Bar
                TextField("Search for a location", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchQuery) { newValue in
                        searchLocation()
                    }
                
                // Map View
                Map(
                    coordinateRegion: Binding(
                        get: { mapRegion ?? defaultRegion() },
                        set: { mapRegion = $0 }
                    ),
                    annotationItems: selectedCoordinate.map { [MapPinItem(coordinate: $0)] } ?? []
                ) { item in
                    MapPin(coordinate: item.coordinate, tint: .red)
                }
                .frame(height: 400)
                .padding(.horizontal)
                .onAppear(perform: setupLocationManager)
                
                // Next Button
                NavigationLink(destination: FinalOnboardingView(user: $user).navigationBarBackButtonHidden(true)) {
                    Text("Next")
                        .padding()
                }
                
                Spacer()
                Image("Reshufflelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 80)
                    .padding()
            }
            .onAppear {
                initializeLocation()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            if let currentLocation = locationManager.location?.coordinate {
                setMapRegion(to: currentLocation)
            }
        }
    }
    
    private func initializeLocation() {
        if let currentLocation = locationManager.location?.coordinate {
            setMapRegion(to: currentLocation)
        }
    }
    
    private func searchLocation() {
        guard !searchQuery.isEmpty else { return }
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchQuery
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response, let mapItem = response.mapItems.first else { return }
            let coordinate = mapItem.placemark.coordinate
            setMapRegion(to: coordinate)
        }
    }
    
    private func setMapRegion(to coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapRegion = region
        selectedCoordinate = coordinate
        user.region = region
    }
    
    private func defaultRegion() -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default location (San Francisco)
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}

struct SeventhView: View {
    @State private var desc: String = ""
    @State private var company: String = ""
    @State private var phoneNumber: String = ""
    @State private var whatsapp: String = ""
    @State private var address: String = ""
    @State private var website: String = ""
    @State private var linkedIn: String = ""
    @State private var instagram: String = ""
    @State private var xHandle: String = ""
    @State private var selectedRole: String = "" // New state for selected role
    @StateObject private var userData = UserData.shared
    @Binding var user: BusinessCard
    var name: String

    // Categories and subcategories from SecondView
    let categories: [String: [String]] = [
        "All Cards": [],
        "Tech": ["SDE", "Software Engineer", "Data Scientist", "Network Administrator", "Web Developer", "Lead IOS Developer", "IOS Developer", "iOS Developer", "UX/UI Designer", "Database Administrator", "DevOps Engineer", "IT Consultant", "System Analyst", "Cybersecurity Analyst", "Mobile App Developer", "AI/Machine Learning Engineer", "Game Developer", "QA Tester", "Cloud Solutions Architect", "Tech Support Specialist", "Technical Writer", "Embedded Systems Engineer", "Network Engineer", "Full Stack Developer", "Tester"],
        "Doctor": ["General Practitioner", "Cardiologist", "Dentist", "Orthopedic Surgeon", "Pediatrician", "Ophthalmologist", "Psychiatrist", "Neurologist", "Obstetrician/Gynecologist", "Anesthesiologist", "Radiologist", "Pathologist", "General Surgeon", "Emergency Medicine Physician", "Family Medicine Physician", "Urologist", "Dermatologist", "Oncologist", "Endocrinologist", "Nephrologist"],
        "Education": ["Student", "Teacher", "Professor"],
        "Utility": ["Plumber", "Electrician", "HVAC Technician", "Carpenter", "Mechanic", "Locksmith", "Landscaper", "Painter", "Pool Cleaner", "Appliance Repair Technician", "Roofing Contractor", "Pest Control Technician", "Septic Tank Services", "Glass Installer", "Welder", "Solar Panel Installer", "Elevator Mechanic", "Building Inspector", "Fire Alarm Technician", "Masonry Worker"],
        "Entertainment": ["Actor", "Musician", "Video Game Developer", "Film Director", "Cinematographer", "Sound Engineer", "Choreographer", "Costume Designer", "Makeup Artist", "Stunt Performer", "Film Editor", "Set Designer", "Casting Director", "Storyboard Artist", "Location Manager", "Voice Actor", "Script Supervisor", "Film Producer", "Entertainment Lawyer", "Talent Agent"],
        "Artist": ["Painter", "Sculptor", "Graphic Designer", "Photographer", "Illustrator", "Printmaker", "Ceramic Artist", "Textile Designer", "Jewelry Designer", "Glassblower", "Digital Artist", "Street Artist", "Installation Artist", "Muralist", "Collage Artist", "Comic Book Artist", "Cartoonist", "Conceptual Artist", "Mixed Media Artist", "Tattoo Artist"],
        "Management": ["Project Manager", "HR Manager", "Financial Analyst", "Marketing Manager", "Operations Manager", "Product Manager", "Sales Manager", "Supply Chain Manager", "Business Analyst", "Quality Assurance Manager", "Risk Manager", "IT Manager", "Event Planner", "Public Relations Manager", "Brand Manager", "Facilities Manager", "Customer Success Manager", "Research and Development Manager", "Training and Development Manager", "Legal Operations Manager"],
        "Others": []
    ]

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: OfficeLocationView(user: $user).navigationBarBackButtonHidden(true)) {
                        Text("Skip")
                            .foregroundColor(Color.gray)
                            .padding(.trailing)
                    }
                }
                
                Spacer()
                Spacer()
                Text("\tTell us more\nabout yourself?")
                    .font(.largeTitle).fontWeight(.bold)
                Spacer()
                Spacer()
                Form {
                    Section(header: Text("Additional Information").font(.subheadline).padding(.bottom)) {

                        TextField("Current Company", text: $company)
                            .onChange(of: company) { newCompany in
                                user.company = newCompany
                            }

                        // Custom Picker Row for Role
                        PickerRow(label: "Role", selection: $selectedRole, options: categories[user.profession] ?? [])
                            .onChange(of: selectedRole) { newRole in
                                user.role = newRole
                            }
                        
                        TextField("Phone Number", text: $phoneNumber)
                            .onChange(of: phoneNumber) { newPhoneNumber in
                                user.phoneNumber = newPhoneNumber
                            }
                        
                        TextField("Whatsapp Number", text: $whatsapp)
                            .onChange(of: whatsapp) { newWhatsapp in
                                user.whatsapp = newWhatsapp
                            }

                        TextField("Website", text: $website)
                            .onChange(of: website) { newWebsite in
                                user.website = newWebsite
                            }
                        
                        TextField("LinkedIn", text: $linkedIn)
                            .onChange(of: linkedIn) { newLinkedIn in
                                user.linkedIn = newLinkedIn
                            }
                        
                        TextField("Instagram", text: $instagram)
                            .onChange(of: instagram) { newInstagram in
                                user.instagram = newInstagram
                            }
                        
                        TextField("X Handle", text: $xHandle)
                            .onChange(of: xHandle) { newXHandle in
                                user.xHandle = newXHandle
                            }
                    }
                }.frame(height: 450)
                
                Button(action: {
                    user.description = desc
                    user.company = company
                    user.role = selectedRole
                    user.phoneNumber = phoneNumber
                    user.whatsapp = whatsapp
                    user.address = address
                    user.website = website
                    user.linkedIn = linkedIn
                    user.instagram = instagram
                    user.xHandle = xHandle
                }) {
                    NavigationLink(destination: OfficeLocationView(user: $user).navigationBarBackButtonHidden(true)) {
                        Text("Next")
                            .padding(.top)
                    }
                }
                Spacer()
                Image("Reshufflelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 80)
                    .foregroundColor(.green)
                    .padding()
            }
        }
    }
}

// Custom Picker Row View
struct PickerRow: View {
    var label: String
    @Binding var selection: String
    var options: [String]

    var body: some View {
        Menu {
            Picker(selection: $selection, label: EmptyView()) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        } label: {
            HStack {
                Text(label)
                    .foregroundColor(.gray)
                Spacer()
                Text(selection.isEmpty ? "Select" : selection)
                    .foregroundColor(selection.isEmpty ? .gray : .black)
            }
        }
    }
}


struct FinalOnboardingView: View {
    @State private var showPreviewCard = false
    @State private var isButtonClicked = false
    @Binding var user: BusinessCard
    @State private var userData: [String: Any] = [:]
    @State private var errorMessage = ""
    @State private var isErrorAlertPresented = false
    @State private var navigateToFirstPage = false
    @State private var isEditCardsPresented = false


    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image("FinalOnboarding")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .foregroundColor(.green)

                Text("We're all set")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                Text("Your card is successfully created!")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)

                if showPreviewCard {
                    CustomCardViewPreview(businessCard: BusinessCard(
                        id: UUID(),
                        name: user.name,
                        profession: user.profession,
                        email: user.email,
                        company: user.company,
                        role: user.role,
                        description: user.description,
                        phoneNumber: user.phoneNumber,
                        whatsapp: user.whatsapp,
                        address: user.address,
                        website: user.website,
                        linkedIn: user.linkedIn,
                        instagram: user.instagram,
                        xHandle: user.xHandle,
                        region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                        trackingMode: .follow
                    ))
                    .previewLayout(.sizeThatFits)
                    
                    .padding(.top,20)
                    
                }
                Spacer()

                VStack {
                    ZStack {
                        Button(action: {
                            withAnimation {
                                showPreviewCard.toggle()
                            }
                        }) {
                            Text("Preview Card")
                                .foregroundColor(.black)
                                .padding()
                                .frame(width: 150, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.yellow)
                                )
                        }
                        
                        if showPreviewCard {
                            HStack {
                                Spacer()
                                Button(action: {
                                    isEditCardsPresented.toggle()
                                    print("Edit button tapped")
                                }) {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(.black)
                                        .padding(8)
                                        .background(Color.yellow)
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 10)
                            }
                        }
                    }
                }
                .sheet(isPresented: $isEditCardsPresented) {
                    EditCardsPreviewCard(user: $user)
                }

                NavigationLink(destination: FirstPage().navigationBarBackButtonHidden(true), isActive: $navigateToFirstPage) {
                    Button(action: {
                        if let userId = Auth.auth().currentUser?.uid {
                            userData = [
                                "uid": userId,
                                "name": user.name,
                                "profession": user.profession,
                                "email": user.email,
                                "company": user.company,
                                "role": user.role,
                                "description": user.description,
                                "phoneNumber": user.phoneNumber,
                                "whatsapp": user.whatsapp,
                                "address": user.address,
                                "website": user.website,
                                "linkedIn": user.linkedIn,
                                "instagram": user.instagram,
                                "xHandle": user.xHandle,
                                "latitude": user.region.center.latitude,
                                "longitude": user.region.center.longitude
                            ]
                            
                            Firestore.firestore().collection("UserDatabase").document(userId).setData(userData) { error in
                                if let error = error {
                                    print("Error storing user data: \(error.localizedDescription)")
                                    errorMessage = "Failed to store user data."
                                    isErrorAlertPresented = true
                                } else {
                                    print("Successfully entered data!")
                                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                                    navigateToFirstPage = true
                                }
                            }
                        }
                    }) {
                        Text("Let's go!")
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 150, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.black)
                            )
                    }
                }
                .padding(.top)
                
                .alert(isPresented: $isErrorAlertPresented) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct BusinessCardView: View {
    var businessCard: BusinessCard

    var body: some View {
        VStack {
            Spacer()

            Text(businessCard.name)
                .font(.title)
                .fontWeight(.bold)

            Text(businessCard.profession)

            Text(businessCard.email)

            Text(businessCard.company)

            Text(businessCard.role)

            Text(businessCard.description)

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct Onboarding_Previews: PreviewProvider {
    
    
    static var previews: some View {
        let userData = UserData()
        Onboarding(userData: userData)
    }
}

