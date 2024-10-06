//
//  BusinessCardSaved.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 09/03/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Firebase
import PassKit

// Assuming you have a model named UserData
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
            Image("LOGO")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 45)
                .padding(.top, 20)
            
            Spacer()
            
            Text(userData.name)
                .font(.system(size: 30))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .onTapGesture {
                            copyToClipboard(userData.name)
                        }
            Text(userData.company)
                .font(.system(size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .onTapGesture {
                            copyToClipboard(userData.company)
                        }
            
            Spacer()
                

                VStack(alignment: .leading) {
                    HStack {
                        Text("Role:")
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.5)
                        Spacer()
                    }
                    

                    HStack {
                        Text(userData.profession)
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                        Spacer()
                    }
                }
                
                // Email
            VStack(alignment: .leading) {
                HStack {
                    Text("Email:")
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(0.5)
                    Spacer()
                }
                // User's email
                HStack {
                    Text(userData.email)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                        .onTapGesture {
                                        // Open the mail app with the email address
                                        if let emailURL = URL(string: "mailto:\(userData.email)") {
                                            UIApplication.shared.open(emailURL)
                                        }
                                    }
                    Spacer()
                }
                .contextMenu {
                    Button(action: {
                        copyToClipboard(userData.email)
                    }) {
                        Text("Copy")
                        Image(systemName: "doc.on.doc")
                    }
                }
            }

                
            VStack(alignment: .leading) {
                HStack {
                    Text("Phone Number:")
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(0.5)
                    Spacer()
                }
                HStack {
                    Text(userData.phoneNumber)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                        .onTapGesture {
                            if let phoneURL = URL(string: "tel:\(userData.phoneNumber)") {
                                UIApplication.shared.open(phoneURL)
                            }
                        }
                    Spacer()
                }
            }
            
            // Website
            VStack(alignment: .leading) {
                HStack {
                    Text("Website:")
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(0.5)
                    Spacer()
                }
                HStack {
                Text(userData.website)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)
                    .onTapGesture {
                        if let websiteURL = URL(string: userData.website) {
                            UIApplication.shared.open(websiteURL)
                        }
                    }
                    Spacer()
                    }
            }
            
            // LinkedIn
            VStack(alignment: .leading) {
                HStack {
                    Text("LinkedIn:")
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(0.5)
                    Spacer()
                }
                HStack {
                    Text(userData.linkedIn)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                        .onTapGesture {
                            if let linkedInURL = URL(string: userData.linkedIn) {
                                UIApplication.shared.open(linkedInURL)
                            }
                        }
                    Spacer()
                }
            }
            
            // Instagram
            VStack(alignment: .leading) {
                HStack {
                    Text("Instagram:")
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(0.5)
                    Spacer()
                }
                HStack {
                    Text(userData.instagram)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                        .onTapGesture {
                            if let instagramURL = URL(string: "https://instagram.com/\(userData.instagram)") {
                                UIApplication.shared.open(instagramURL)
                            }
                        }
                    Spacer()
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Image(systemName: "shuffle")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding(20)
                Spacer()
            }
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
                            userData = UserDataBusinessCard(
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
                    } else {
                        print("Document does not exist")
                        userData = UserDataBusinessCard(
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
                    isFetchingData = false
                }
            }
        } else {
            print("No user logged in")
            userData = UserDataBusinessCard(
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
            isFetchingData = false
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
            linkedIn: "",
            instagram: "",
            xHandle: ""
        ))

        return BusinessCardSaved(userData: userData)
    }
}
