import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Firebase
struct UserDataBusinessCard: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var profession: String
    var role: String
    var company: String
    var email: String
    var phoneNumber: String
    var website: String
    var address: String
    var linkedIn: String
    var instagram: String
    var xHandle: String
    var cardColor: String? // Make it optional
    
    // Provide a default initialization
    init(
        id: String? = nil,
        name: String,
        profession: String,
        role: String,
        company: String,
        email: String,
        phoneNumber: String,
        website: String,
        address: String,
        linkedIn: String,
        instagram: String,
        xHandle: String,
        cardColor: String? = nil // Default to nil
    ) {
        self.id = id
        self.name = name
        self.profession = profession
        self.role = role
        self.company = company
        self.email = email
        self.phoneNumber = phoneNumber
        self.website = website
        self.address = address
        self.linkedIn = linkedIn
        self.instagram = instagram
        self.xHandle = xHandle
        self.cardColor = cardColor ?? "defaultColor" // Provide a default if nil
    }
    
    // Custom coding keys to handle potential missing fields
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profession
        case role
        case company
        case email
        case phoneNumber
        case website
        case address
        case linkedIn
        case instagram
        case xHandle
        case cardColor
    }
    
    // Custom init from Decoder to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        profession = try container.decode(String.self, forKey: .profession)
        role = try container.decode(String.self, forKey: .role)
        company = try container.decode(String.self, forKey: .company)
        email = try container.decode(String.self, forKey: .email)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        website = try container.decode(String.self, forKey: .website)
        address = try container.decode(String.self, forKey: .address)
        linkedIn = try container.decode(String.self, forKey: .linkedIn)
        instagram = try container.decode(String.self, forKey: .instagram)
        xHandle = try container.decode(String.self, forKey: .xHandle)
        cardColor = try container.decodeIfPresent(String.self, forKey: .cardColor) ?? "defaultColor"
    }
}

struct BusinessCardSaved: View {
    @Binding var userData: UserDataBusinessCard
    var cardColor: String?

    
    var body: some View {
        
            VStack(spacing: 24) {
                // Profile Header
                profileHeaderSection
                
                // Contact Information Section
                ContactInformationSection(userData: userData)
                
                // Social Links Section
                SocialLinksSection(userData: userData)
            }
            .padding()
        
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Contact Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var profileHeaderSection: some View {
         VStack(spacing: 12) {
             VStack(spacing: 4) {
                 Text(userData.name)
                     .font(.title2)
                     .fontWeight(.semibold)
                     .foregroundColor(.primary)
                 
                 VStack(spacing: 2) {
                     Text(userData.profession)
                         .font(.headline)
                         .foregroundColor(.secondary)
                     
                     Text("\(userData.role) | \(userData.company)")
                         .font(.subheadline)
                         .foregroundColor(.secondary)
                 }
             }
             .multilineTextAlignment(.center)
             .frame(maxWidth: .infinity)
             .frame(height: 200)
             .padding()
             .background(
                 RoundedRectangle(cornerRadius: 12)
                     .fill(backgroundColorFromString())
                     .shadowElegant()
             )
         }
     }
     
     // Helper method to convert string to Color
    // Helper method to convert string to Color
    private func backgroundColorFromString() -> Color {
        guard let cardColor = userData.cardColor else {
            return Color(UIColor.systemBackground)
        }
        
        // If it's a hex color string
        if cardColor.hasPrefix("#") {
            if let color = Color(hex: cardColor) {
                return color.opacity(0.1)
            }
        }
        
        // Predefined color mapping
        switch cardColor.lowercased() {
        case "blue": return .blue.opacity(0.1)
        case "green": return .green.opacity(0.1)
        case "red": return .red.opacity(0.1)
        case "purple": return .purple.opacity(0.1)
        case "orange": return .orange.opacity(0.1)
        case "pink": return .pink.opacity(0.1)
        case "gray": return .gray.opacity(0.1)
        case "teal": return .teal.opacity(0.1)
        case "indigo": return .indigo.opacity(0.1)
        default:
            // If color string doesn't match predefined colors,
            // attempt to create a custom color or fallback to system background
            return Color(UIColor.systemBackground)
        }
    }
}


// Contact Information Section
struct ContactInformationSection: View {
    let userData: UserDataBusinessCard
    
    var body: some View {
        VStack(spacing: 12) {
            ContactDetailRow(
                systemImage: "envelope",
                title: "Email",
                detail: userData.email,
                action: { openURL("mailto:\(userData.email)") }
            )
            
            Divider()
            
            ContactDetailRow(
                systemImage: "phone",
                title: "Phone",
                detail: userData.phoneNumber,
                action: { openURL("tel:\(userData.phoneNumber)") }
            )
            
            Divider()
            
            ContactDetailRow(
                systemImage: "globe",
                title: "Website",
                detail: userData.website,
                action: { openURL(userData.website) }
            )
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadowElegant()
        .padding(.horizontal)
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// Social Links Section
struct SocialLinksSection: View {
    let userData: UserDataBusinessCard
    
    var body: some View {
        HStack(spacing: 30) {
            SocialButton(platform: .linkedin, username: userData.linkedIn)
            SocialButton(platform: .instagram, username: userData.instagram)
            SocialButton(platform: .x, username: userData.xHandle)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadowElegant()
        .padding(.horizontal)
    }
}

// Reusable Contact Detail Row
struct ContactDetailRow: View {
    let systemImage: String
    let title: String
    let detail: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(detail)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Social Button Enum and View
enum SocialPlatform {
    case linkedin
    case instagram
    case x
    
    var systemImage: String {
        switch self {
        case .linkedin: return "linkedin"
        case .instagram: return "instagram"
        case .x: return "xmark"
        }
    }
}

struct SocialButton: View {
    let platform: SocialPlatform
    let username: String
    
    var body: some View {
        Button(action: openSocialProfile) {
            Image(platform.systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openSocialProfile() {
        var urlString: String
        switch platform {
        case .linkedin:
            urlString = "https://linkedin.com/in/\(username)"
        case .instagram:
            urlString = "https://instagram.com/\(username)"
        case .x:
            urlString = "https://twitter.com/\(username)"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// Elegant Shadow Extension
extension View {
    func shadowElegant() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
//struct ContactInfoView: View {
//    let label: String
//    let content: String
//    let action: () -> Void
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text("\(label):")
//                    .font(.system(size: 14, weight: .bold))
//                    .foregroundColor(.white.opacity(0.5))
//                Spacer()
//            }
//            HStack {
//                Text(content)
//                    .font(.system(size: 18, weight: .bold))
//                    .foregroundColor(.white)
//                    .padding(.bottom, 5)
//                    .onTapGesture(perform: action)
//                Spacer()
//            }
//        }
//    }
//}

//struct SocialIconView: View {
//    let iconName: String
//    let urlString: String
//    
//    var body: some View {
//        Button(action: {
//            if let url = URL(string: urlString) {
//                UIApplication.shared.open(url)
//            }
//        }) {
//            Image(iconName)
//                .resizable()
//                .frame(width: 32, height: 32)
//                .foregroundColor(.white)
//        }
//    }
//}

struct BusinessCardSaved_Previews: PreviewProvider {
    static var previews: some View {
        let userData = Binding.constant(UserDataBusinessCard(
            name: "John Doe",
            profession: "Software Engineer",
            role: "iOS Developer",
            company: "ABC Inc.",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890",
            website: "www.johndoe.com",
            address: "",
            linkedIn: "https://linkedin.com/in/johndoe",
            instagram: "johndoe",
            xHandle: "johndoe",
            cardColor: ""
        ))

        return BusinessCardSaved(userData: userData)
    }
}
