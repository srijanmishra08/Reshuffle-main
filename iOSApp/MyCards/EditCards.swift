import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices
import SafariServices
import SwiftUI
import SafariServices

// Instagram OAuth Configuration
struct InstagramConfig {
    static let clientID = "1103931211109084"
    static let clientSecret = "e2bd131f3d7f47e892bbc49fad17c834"
    static let redirectURI = "com.srijan.Reshuffle://oauth" // Use your app's custom URL scheme
    static let scope = "instagram_basic,instagram_manage_insights,pages_show_list"
}

class InstagramAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username: String = ""
    
    func authenticate() -> URL? {
        // Use Facebook's OAuth dialog for Instagram Business
        let baseURL = "https://www.facebook.com/v21.0/dialog/oauth"
        let queryItems = [
            "client_id": InstagramConfig.clientID,
            "redirect_uri": InstagramConfig.redirectURI,
            "scope": InstagramConfig.scope,
            "response_type": "code",
            "state": UUID().uuidString // For security
        ]
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url
    }
    
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("Failed to get authorization code")
            return
        }
        
        exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) {
        let tokenEndpoint = "https://graph.facebook.com/v21.0/oauth/access_token"
        let parameters = [
            "client_id": InstagramConfig.clientID,
            "client_secret": InstagramConfig.clientSecret,
            "redirect_uri": InstagramConfig.redirectURI,
            "code": code
        ]
        
        var components = URLComponents(string: tokenEndpoint)
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components?.url else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Token exchange error: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let accessToken = json?["access_token"] as? String {
                    self?.getInstagramAccountInfo(accessToken: accessToken)
                }
            } catch {
                print("Error parsing token response: \(error)")
            }
        }.resume()
    }
    
    private func getInstagramAccountInfo(accessToken: String) {
        // First get the pages the user has access to
        let graphEndpoint = "https://graph.facebook.com/v21.0/me/accounts"
        let parameters = [
            "access_token": accessToken,
            "fields": "instagram_business_account,name"
        ]
        
        var components = URLComponents(string: graphEndpoint)
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components?.url else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let accounts = json?["data"] as? [[String: Any]],
                   let firstAccount = accounts.first,
                   let instagramAccount = firstAccount["instagram_business_account"] as? [String: Any],
                   let instagramAccountId = instagramAccount["id"] as? String {
                    self?.fetchInstagramBusinessProfile(accessToken: accessToken, instagramAccountId: instagramAccountId)
                }
            } catch {
                print("Error parsing accounts response: \(error)")
            }
        }.resume()
    }
    
    private func fetchInstagramBusinessProfile(accessToken: String, instagramAccountId: String) {
        let graphEndpoint = "https://graph.facebook.com/v21.0/\(instagramAccountId)"
        let parameters = [
            "access_token": accessToken,
            "fields": "username,profile_picture_url,name"
        ]
        
        var components = URLComponents(string: graphEndpoint)
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components?.url else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let username = json?["username"] as? String {
                    DispatchQueue.main.async {
                        self?.username = username
                        self?.isAuthenticated = true
                    }
                }
            } catch {
                print("Error parsing profile response: \(error)")
            }
        }.resume()
    }
}

struct InstagramAuthWebView: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool
    var onCallback: (URL) -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
struct EditCards: View {
    @State private var isDetailViewActive = false
    @State private var isSaveButtonTapped = false
    @State private var showAlert = false
    @State private var selectedTab: Int? = nil
    @StateObject public var userDataViewModel: UserDataViewModel
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    
    @State private var profession: String = ""
    @State private var role: String = ""
    @State private var uid: String = ""
    
    @State private var company: String = ""
    @State private var whatsapp: String = ""
    @State private var linkedIn: String = ""
    @State private var description: String = ""
    @State private var instagram: String = ""
    @State private var xHandle: String = ""
    @State private var website: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var selectedCardColor = Color.blue
    @StateObject private var instagramAuth = InstagramAuthManager()
    @State private var showingInstagramAuth = false

    // Color options
    let cardColors: [Color] = [
           .blue,
           .green,
           .purple,
           .red,
           .orange,
           .teal,
           .indigo
       ]
    
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
//        "All Cards": [],
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
        ]
//        "Others": []
    ]
    
    
    let db = Firestore.firestore()

    var body: some View {
       
            ScrollView {
                    VStack(spacing:0) {
                        VStack{
                            Spacer()
                            if let businessCard = userDataViewModel.businessCard {
                                CustomCardViewPreview(businessCard: businessCard, cardColor: UIColor(selectedCardColor))
                                    .padding()
                                    .padding(.top)
                                    .padding(.top)

                                    .padding(.top)
                                    .padding(.top)
                                    .padding(.top)

                                    .padding(.bottom)
                                    .padding(.bottom)
                                    .padding(.bottom)
                                    .padding(.bottom)

                            } else {
                                Text("Loading...")
                            }
                            
                            Spacer()
                            Spacer()
                            Spacer()
                        }
                        // Add color selection section
                                            VStack {
                                                HStack {
                                                    Text("Card Color")
                                                        .font(.title2)
                                                        .padding()
                                                        .padding(.horizontal)
                                                    Spacer()
                                                }
                                                
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 10) {
                                                        ForEach(cardColors, id: \.self) { color in
                                                            Button(action: {
                                                                selectedCardColor = color
                                                            }) {
                                                                Circle()
                                                                    .fill(color)
                                                                    .frame(width: 50, height: 50)
                                                                    .overlay(
                                                                        Circle()
                                                                            .stroke(selectedCardColor == color ? Color.black : Color.clear, lineWidth: 2)
                                                                    )
                                                            }
                                                        }
                                                    }
                                                    .padding()
                                                }
                                            }
                        VStack(spacing:0){
                            
                            VStack{
                                
                                HStack {
                                    Text("Personal Information")
                                        .font(.title2)
                                        .padding()
                                        .padding(.horizontal)
                                    Spacer()
                                }
                                
                                RoundedTextField(label: "Name", text: $name)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Email Id", text: $email)
                                    .frame(height: 90)
                                    .autocapitalization(.none)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Phone number", text: $phoneNumber)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                
//                                RoundedTextField(label: "Personal Address", text: $address)
//                                    .frame(height: 90)
//                                    .padding(.horizontal)
                                HStack {
                                    Text("Professional Information")
                                        .font(.title2)
                                        .padding()
                                        .padding(.horizontal)
                                    Spacer()
                                }
//                                RoundedTextField(label: "Profession", text: $profession)
//                                    .frame(height: 90)
//                                    .padding(.horizontal)
//                                RoundedTextField(label: "Role", text: $role)
//                                    .frame(height: 90)
//                                    .padding(.horizontal)
                                // Profession Selection
//                                ScrollableCategory(title: "Profession", options: professions, selectedOption: $profession)
//
//                                                       // Role Selection
//                                ScrollableCategory(title: "Role", options: roles, selectedOption: $role)
                                
                                CategorySelector(categories: categories, categoryIcons: categoryIcons, selectedCategory: $profession)
                                                        
                                if let roles = categories[profession] {
                                    ScrollableCategory(title: "Role", options: roles, selectedOption: $role)
                                                        }
                                                       
                                RoundedTextField(label: "Current Company", text: $company)
                                    .frame(height: 90)
                                    .padding(.horizontal)
//                                RoundedTextField(label: "Description", text: $description)
//                                    .frame(height: 90)
//                                    .padding(.horizontal)
                                Spacer()
                            }
                            
                            VStack{
                                HStack {
                                    Text("Social Media")
                                        .font(.title2)
                                        .padding()
                                        .padding(.horizontal)
                                    Spacer()
                                }
                                
//                                RoundedTextField(label: "Work Email", text: $email)
//                                    .frame(height: 90)
//                                    .padding(.horizontal)
//                                RoundedTextField(label: "Whatsapp Number", text: $whatsapp)
//                                    .frame(height: 90)
//                                    .padding(.horizontal)
//
//                                RoundedTextField(label: "Work Address", text: $address)
//                                    .frame(height: 90)
//                                    .padding(.horizontal)
                                
                                RoundedTextField(label: "Website", text: $website)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                
                                RoundedTextField(label: "LinkedIn Username", text: $linkedIn)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "X Handle", text: $xHandle)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                               
                                        VStack(alignment: .leading) {
                                            Text("Instagram")
                                                .font(.subheadline)
                                                .foregroundColor(Color.gray)
                                                .padding(.bottom, 1)
                                                .padding(.top, 5)
                                                .padding(.leading, 25)
                                            
                                            Button(action: {
                                                if let url = instagramAuth.authenticate() {
                                                    showingInstagramAuth = true
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: instagramAuth.isAuthenticated ? "checkmark.circle.fill" : "link")
                                                        .foregroundColor(instagramAuth.isAuthenticated ? .green : .blue)
                                                    Text(instagramAuth.isAuthenticated ? "Connected as @\(instagramAuth.username)" : "Connect Instagram Account")
                                                        .foregroundColor(instagramAuth.isAuthenticated ? .black : .blue)
                                                }
                                                .padding()
                                                .background(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 1))
                                                .padding([.leading, .trailing])
                                                .padding(.bottom, 5)
                                            }
                                        }
                                        .sheet(isPresented: $showingInstagramAuth) {
                                            if let url = instagramAuth.authenticate() {
                                                InstagramAuthWebView(url: url, isPresented: $showingInstagramAuth) { callbackURL in
                                                    instagramAuth.handleCallback(url: callbackURL)
                                                    showingInstagramAuth = false
                                                }
                                            }
                                        }
                                    
                                    
                                
//                                RoundedTextField(label: "Latitude", text: Binding(
//                                    get: { "\(latitude)" },
//                                    set: {
//                                        if let value = Double($0) {
//                                            latitude = value
//                                        }
//                                    }
//                                ))
//                                .frame(height: 90)
//                                .padding(.horizontal)
//
//                                RoundedTextField(label: "Longitude", text: Binding(
//                                    get: { "\(longitude)" },
//                                    set: {
//                                        if let value = Double($0) {
//                                            longitude = value
//                                        }
//                                    }
//                                ))
//                                .frame(height: 90)
//                                .padding(.horizontal)
                                
                            }
                            Button(action: {
                                saveUserData()
                            }) {
                                Text("Save")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(15)
                                    .frame(width: 100)
                            }
                            .padding()
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("Card Saved"), message: Text("Your card has been saved successfully."), dismissButton: .default(Text("OK")))
                            }
                        }
                    }.navigationTitle("Edit Cards")
                        
                }
            
            .onAppear {
                if let userID = Auth.auth().currentUser?.uid {
                    db.collection("UserDatabase").document(userID).getDocument { (document, error) in
                        if let document = document, document.exists {
                            if let data = document.data() {
                                uid = data["uid"] as? String ?? userID  // Use the saved UID or current user ID
                                name = data["name"] as? String ?? ""
                                email = data["email"] as? String ?? ""
                                phoneNumber = data["phoneNumber"] as? String ?? ""
                                address = data["address"] as? String ?? ""
                                profession = data["profession"] as? String ?? ""
                                role = data["role"] as? String ?? ""
                                company = data["company"] as? String ?? ""
                                whatsapp = data["whatsapp"] as? String ?? ""
                                linkedIn = data["linkedIn"] as? String ?? ""
                                description = data["description"] as? String ?? ""
                                instagram = data["instagram"] as? String ?? ""
                                xHandle = data["xHandle"] as? String ?? ""
                                website = data["website"] as? String ?? ""
                                latitude = data["latitude"] as? Double ?? 0.0
                                longitude = data["longitude"] as? Double ?? 0.0
                                // Load card color
                                if let colorHex = data["cardColor"] as? String {
                                    selectedCardColor = Color(hex: colorHex) ?? .blue
                                }
                            }
                        } else {
                            print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            }
        
    }

    

    private func saveUserData() {
        showAlert = true

        if let userID = Auth.auth().currentUser?.uid {
            db.collection("UserDatabase").document(userID).setData([
                "uid": userID,  // Explicitly add the uid field
                "name": name,
                "profession": profession,
                "email": email,
                "company": company,
                "role": role,
                "description": description,
                "phoneNumber": phoneNumber,
                "whatsapp": whatsapp,
                "address": address,
                "website": website,
                "linkedIn": linkedIn,
                "instagram": instagramAuth.username,
                "xHandle": xHandle,
                "latitude": latitude,
                "longitude": longitude,
                "cardColor": selectedCardColor.toHexString()
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
}
// Extension to convert Color to Hex String
extension Color {
    func toHexString() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let hexString = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        return hexString
    }
}
// Add a Color extension to convert hex to Color
extension Color {
    init?(hex: String) {
        let r, g, b: CGFloat
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255

                    self.init(red: r, green: g, blue: b)
                    return
                }
            }
        }
        return nil
    }
}
struct RoundedTextField: View {
    var label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label)")
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .padding(.bottom, 1)
                .padding(.top, 5)
                .padding(.leading, 25)

            TextField(label, text: $text)
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 1))
                .padding([.leading, .trailing])
                .padding(.bottom, 5)
        }
    }
}

struct ScrollableCategory: View {
    let title: String
    let options: [String]
    @Binding var selectedOption: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Role")
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .padding(.bottom, 1)
                .padding(.top, 5)
                .padding(.leading, 25)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selectedOption = option
                        }) {
                            Text(option)
                                .font(.body)
                                .padding()
                                .background(selectedOption == option ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.3))
                                .cornerRadius(15)
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal)
            }
        }.padding(.horizontal)
    }
}

struct CategorySelector: View {
    let categories: [String: [String]]
    let categoryIcons: [String: String]
    @Binding var selectedCategory: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Profession")
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .padding(.bottom, 1)
                .padding(.top, 5)
                .padding(.leading, 25)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories.keys.sorted(), id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            VStack {
                                Image(systemName: categoryIcons[category] ?? "questionmark.circle")
                                    .font(.largeTitle)
                                    .padding()
                                    .background(selectedCategory == category ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.3))
                                    .cornerRadius(10)
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(.black)
                            }
                        }.padding(.horizontal, 5)
                    }
                }.padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
}
struct EditCards_Previews: PreviewProvider {
    static var previews: some View {
        let userDataViewModel = UserDataViewModel()
        EditCards(userDataViewModel: userDataViewModel)
    }
}
