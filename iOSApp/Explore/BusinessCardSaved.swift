import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Firebase

struct UserDataBusinessCard: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var profession: String
    var company: String
    var email: String
    var phoneNumber: String
    var website: String
    var address: String
    var linkedIn: String
    var instagram: String
    var xHandle: String
}

struct BusinessCardSaved: View {
    @StateObject private var userDataViewModel = UserDataViewModel()
    @Binding var userData: UserDataBusinessCard
    @State private var isFetchingData = false

    var body: some View {
        VStack(spacing: 20) {
            // Section 1: Name, Role, Company
            VStack(spacing: 10) {
                Text(userData.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .onTapGesture {
                        copyToClipboard(userData.name)
                    }
                
                Text(userData.profession)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                    .onTapGesture {
                        copyToClipboard(userData.profession)
                    }
                
                Text(userData.company)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.gray)
                    .onTapGesture {
                        copyToClipboard(userData.company)
                    }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5))
            .padding(.horizontal, 20)
            
            // Section 2: Contact Information
            VStack(spacing: 15) {
                ContactInfoView(label: "Email", content: userData.email) {
                    openURL("mailto:\(userData.email)")
                }
                
                ContactInfoView(label: "Phone Number", content: userData.phoneNumber) {
                    openURL("tel:\(userData.phoneNumber)")
                }
                
                ContactInfoView(label: "Website", content: userData.website) {
                    openURL(userData.website)
                }
            }
            .padding(.horizontal, 20)
            
            // Section 3: Social Profiles
            VStack(spacing: 15) {
                HStack(spacing: 30) {
                    SocialIconView(iconName: "linkedin", urlString: "https://linkedin.com/in/\(userData.linkedIn)")
                    SocialIconView(iconName: "instagram", urlString: "https://instagram.com/\(userData.instagram)")
                    SocialIconView(iconName: "xmark", urlString: "https://twitter.com/\(userData.xHandle)")
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.black)
                .shadow(radius: 5)
        )
        .onAppear {
            fetchUserData()
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    func fetchUserData() {
        isFetchingData = true
        if let currentUserUID = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("UserDatabase").document(currentUserUID).getDocument { (document, error) in
                DispatchQueue.main.async {
                    if let document = document, document.exists {
                        do {
                            let user = try document.data(as: UserDataBusinessCard.self)
                            userData = user
                            print("User data fetched successfully: \(userData)")
                        } catch {
                            print("Error decoding user data: \(error.localizedDescription)")
                            userData = defaultUserData()
                        }
                    } else {
                        print("Document does not exist")
                        userData = defaultUserData()
                    }
                    isFetchingData = false
                }
            }
        } else {
            print("No user logged in")
            userData = defaultUserData()
            isFetchingData = false
        }
    }

    private func defaultUserData() -> UserDataBusinessCard {
        UserDataBusinessCard(
            id: "",
            name: "Unknown",
            profession: "",
            company: "",
            email: "",
            phoneNumber: "",
            website: "",
            address: "",
            linkedIn: "",
            instagram: "",
            xHandle: ""
        )
    }
}

struct ContactInfoView: View {
    let label: String
    let content: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(label):")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            HStack {
                Text(content)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 5)
                    .onTapGesture(perform: action)
                Spacer()
            }
        }
    }
}

struct SocialIconView: View {
    let iconName: String
    let urlString: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }) {
            Image(iconName)
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.white)
        }
    }
}

struct BusinessCardSaved_Previews: PreviewProvider {
    static var previews: some View {
        let userData = Binding.constant(UserDataBusinessCard(
            name: "John Doe",
            profession: "Software Engineer",
            company: "ABC Inc.",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890",
            website: "www.johndoe.com",
            address: "",
            linkedIn: "https://linkedin.com/in/johndoe",
            instagram: "johndoe",
            xHandle: "johndoe"
        ))

        return BusinessCardSaved(userData: userData)
    }
}
