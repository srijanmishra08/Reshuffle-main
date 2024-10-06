import SwiftUI
import FirebaseFirestore
import FirebaseAuth

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
    @State private var company: String = ""
    @State private var whatsapp: String = ""
    @State private var linkedIn: String = ""
    @State private var description: String = ""
    @State private var instagram: String = ""
    @State private var xHandle: String = ""
    @State private var website: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text("Edit Cards")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        Spacer()
                        Spacer()
                    }
                    .padding()
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3))
                    
                    Spacer()
                    Spacer()
                    
                    VStack(spacing:0) {
                        
                        VStack{
                            
                            if let businessCard = userDataViewModel.businessCard {
                                CustomCardViewPreview(businessCard: businessCard)
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
                                RoundedTextField(label: "Personal Address", text: $address)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Profession", text: $profession)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Role", text: $role)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Current Company", text: $company)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Work Email", text: $email)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Whatsapp Number", text: $whatsapp)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                
                                RoundedTextField(label: "Work Address", text: $address)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "LinkedIn Username", text: $linkedIn)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Website", text: $website)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "X Handle", text: $xHandle)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                RoundedTextField(label: "Instagram", text: $instagram)
                                    .frame(height: 90)
                                    .padding(.horizontal)
                                
                                RoundedTextField(label: "Latitude", text: Binding(
                                    get: { "\(latitude)" },
                                    set: {
                                        if let value = Double($0) {
                                            latitude = value
                                        }
                                    }
                                ))
                                .frame(height: 90)
                                .padding(.horizontal)

                                RoundedTextField(label: "Longitude", text: Binding(
                                    get: { "\(longitude)" },
                                    set: {
                                        if let value = Double($0) {
                                            longitude = value
                                        }
                                    }
                                ))
                                .frame(height: 90)
                                .padding(.horizontal)
                                
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
                    }
                }
            }
            .onAppear {
                if let userID = Auth.auth().currentUser?.uid {
                    db.collection("UserDatabase").document(userID).getDocument { (document, error) in
                        if let document = document, document.exists {
                            if let data = document.data() {
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
                            }
                        } else {
                            print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            }
        }
    }

    private func saveUserData() {

        showAlert = true

        if let userID = Auth.auth().currentUser?.uid {
            db.collection("UserDatabase").document(userID).setData([
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
                "instagram": instagram,
                "xHandle": xHandle,
                "latitude": latitude,
                "longitude": longitude
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

struct EditCards_Previews: PreviewProvider {
    static var previews: some View {
        let userDataViewModel = UserDataViewModel()

        EditCards(userDataViewModel: userDataViewModel)
    }
}
