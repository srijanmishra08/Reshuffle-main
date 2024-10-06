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
    @State private var prof: String = ""
    @State private var isNextButtonDisabled = true
    @Binding var user: BusinessCard

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
                
                TextField("Your Profession", text: $prof)
                    .padding()
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .onChange(of: prof) { newProf in
                        user.profession = newProf
                        updateNextButtonState()
                    }

                Button(action: {
                    user.name = name
                    user.email = emailid
                    user.profession = prof
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
        isNextButtonDisabled = name.isEmpty || emailid.isEmpty || prof.isEmpty
    }
}
       
struct OfficeLocationView: View {
    struct MapPinItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
    
    @State private var searchQuery: String = ""
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapRegion: MKCoordinateRegion?
    @Binding var user: BusinessCard
    var name: String
    @Environment(\.presentationMode) var presentationMode
    @State private var locationManager = CLLocationManager()
    
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
                        searchCompleter.queryFragment = newValue
                    }
                
                // Search Results
                List(searchResults, id: \.description) { result in
                    Text(result.title)
                        .onTapGesture {
                            selectLocation(result)
                        }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(height: 30)
                
                // Map View
                Map(coordinateRegion: Binding(
                                        get: { mapRegion ?? MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)) },
                                        set: { mapRegion = $0 }
                                    ),
                                    annotationItems: selectedCoordinate.map { [MapPinItem(coordinate: $0)] } ?? []
                                ) { item in
                                    MapPin(coordinate: item.coordinate, tint: .red)
                                }
                                .frame(height: 400)
                                .padding(.horizontal,30)
                .onAppear {
                    locationManager.requestWhenInUseAuthorization()
                    locationManager.startUpdatingLocation()
                }
                .gesture(DragGesture().onChanged { value in
                    let location = value.location
                    let coordinate = mapRegion?.center ?? CLLocationCoordinate2D()
                    selectedCoordinate = coordinate
                })
                .onChange(of: selectedCoordinate) { newCoordinate in
                    if let newCoordinate = newCoordinate {
                        mapRegion = MKCoordinateRegion(
                            center: newCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                        user.region = MKCoordinateRegion(
                            center: newCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    }
                }

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    NavigationLink(destination: FinalOnboardingView(user: $user)
                        .navigationBarBackButtonHidden(true)) {
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
            .onAppear {
                searchCompleter.delegate = makeCoordinator()
                
                if let location = locationManager.location {
                    let initialRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    mapRegion = initialRegion
                    selectedCoordinate = location.coordinate
                    user.region = initialRegion
                }
            }
        }
    }
    
    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response, let mapItem = response.mapItems.first else {
                return
            }
            
            self.selectedCoordinate = mapItem.placemark.coordinate
            self.searchResults = []
            
            if let newCoordinate = self.selectedCoordinate {
                self.mapRegion = MKCoordinateRegion(
                    center: newCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                self.user.region = MKCoordinateRegion(
                    center: newCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }

    class Coordinator: NSObject, MKLocalSearchCompleterDelegate {
        var parent: OfficeLocationView

        init(parent: OfficeLocationView) {
            self.parent = parent
        }

        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            parent.searchResults = completer.results
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}

struct SeventhView: View {
    @State private var desc: String = ""
    @State private var company: String = ""
    @State private var role: String = ""
    @State private var phoneNumber: String = ""
    @State private var whatsapp: String = ""
    @State private var address: String = ""
    @State private var website: String = ""
    @State private var linkedIn: String = ""
    @State private var instagram: String = ""
    @State private var xHandle: String = ""
    @State private var locationCoordinate: CLLocationCoordinate2D?
    @StateObject private var userData = UserData.shared
    @Binding var user: BusinessCard
    var name: String
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: OfficeLocationView(user: $user, name: name).navigationBarBackButtonHidden(true)) {
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
                        TextField("Phone Number", text: $phoneNumber)
                            .onChange(of: phoneNumber) { newPhoneNumber in
                                user.phoneNumber = newPhoneNumber
                            }
                        TextField("Current Company", text: $company)
                            .onChange(of: company) { newCompany in
                                user.company = newCompany
                            }

                        TextField("Role", text: $role)
                            .onChange(of: role) { newRole in
                                user.role = newRole
                            }
                        
                        TextField("Whatsapp Number", text: $whatsapp)
                            .onChange(of: whatsapp) { newWhatsapp in
                                user.whatsapp = newWhatsapp
                            }
                        
                        TextField("Description", text: $desc)
                            .onChange(of: desc) { newDesc in
                                user.description = newDesc
                            }
                        
                        TextField("Work Address", text: $address)
                            .onChange(of: address) { newAddress in
                                user.address = newAddress
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
                    user.role = role
                    user.phoneNumber = phoneNumber
                    user.whatsapp = whatsapp
                    user.address = address
                    user.website = website
                    user.linkedIn = linkedIn
                    user.instagram = instagram
                    user.xHandle = xHandle
                }) {
                    NavigationLink(destination: OfficeLocationView(user: $user, name: name).navigationBarBackButtonHidden(true)) {
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
                    .padding()

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
                    .padding()
                    .padding(.top)
                    .padding(.bottom)
                    .padding(.top)
                    .padding(.bottom)
                    .padding(.bottom, 60)
                }
                

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

