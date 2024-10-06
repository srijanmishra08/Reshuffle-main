//
//  BusinessCardMyCards.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 09/03/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RectangularBusinessCard: View {
    @StateObject private var userDataViewModel = UserDataViewModel()
    @Binding var userData: UserDataBusiness
    @State private var isFetchingData = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.0, green: 0.3, blue: 0.2))
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()
                HStack {
                    Spacer()

                    VStack(alignment: .leading, spacing: 5) {
                        HStack{
                            Spacer()
                            Text(userData.name)
                                .font(.system(size: 30).bold())
                                .foregroundColor(.white)
                                .padding(.bottom, 15)
                            Spacer()
                        }
                        HStack{
                            Spacer()
                            Text(userData.profession)
                                .font(.system(size: 18).bold())
                                .foregroundColor(.white)
                                .padding(.bottom, 10)
                            Spacer()
                        }
                        HStack{
                            Spacer()
                            Text(userData.company)
                                .font(.system(size: 18).bold())
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .padding(.trailing, 5)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
                
                HStack{
                    Spacer()
                    Image(systemName: "shuffle")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding(.bottom,20)
                    Spacer()
                }
            }
            .onAppear {
                fetchUserData()
            }

        }
    }



    func fetchUserData() {
        isFetchingData = true
        if let currentUserUID = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("UserDatabase").document(currentUserUID).getDocument { (document, error) in
                DispatchQueue.main.async {
                    if let document = document, document.exists {
                        do {
                            let user = try document.data(as: UserDataBusiness.self)
                            userData = user
                            print("User data fetched successfully: \(userData)")
                        } catch {
                            print("Error decoding user data: \(error.localizedDescription)")
                            userData = UserDataBusiness(
                                id: "",
                                name: "Unknown",
                                profession: "",
                                company: "",
                                email: "",
                                phoneNumber: "",
                                website: ""
                            )
                        }
                    } else {
                        print("Document does not exist")
                        userData = UserDataBusiness(
                            id: "",
                            name: "Unknown",
                            profession: "",
                            company: "",
                            email: "",
                            phoneNumber: "",
                            website: ""
                        )
                    }
                    isFetchingData = false
                }
            }
        } else {
            print("No user logged in")
            userData = UserDataBusiness(
                id: "",
                name: "Unknown",
                profession: "",
                company: "",
                email: "",
                phoneNumber: "",
                website: ""
            )
            isFetchingData = false
        }
    }
}

struct BusinessCardSavedCards: View {
    @StateObject private var userDataViewModel = UserDataViewModel()
    @Binding var userData: UserDataBusiness
    @State private var isFetchingData = false

    var body: some View {
        NavigationView {
            
            VStack {
               
                    RectangularBusinessCard(userData: $userData)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        
                
            }
            .onAppear {
                fetchUserData()
            }
        }
    }
        

    func fetchUserData() {
        isFetchingData = true
        if let currentUserUID = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("UserDatabase").document(currentUserUID).getDocument { (document, error) in
                DispatchQueue.main.async {
                    if let document = document, document.exists {
                        do {
                            let user = try document.data(as: UserDataBusiness.self)
                            userData = user
                            print("User data fetched successfully: \(userData)")
                        } catch {
                            print("Error decoding user data: \(error.localizedDescription)")
                            userData = UserDataBusiness(
                                id: "",
                                name: "Unknown",
                                profession: "",
                                company: "",
                                email: "",
                                phoneNumber: "",
                                website: ""
                            )
                        }
                    } else {
                        print("Document does not exist")
                        userData = UserDataBusiness(
                            id: "",
                            name: "Unknown",
                            profession: "",
                            company: "",
                            email: "",
                            phoneNumber: "",
                            website: ""
                        )
                    }
                    isFetchingData = false
                }
            }
        } else {
            print("No user logged in")
            userData = UserDataBusiness(
                id: "",
                name: "Unknown",
                profession: "",
                company: "",
                email: "",
                phoneNumber: "",
                website: ""
            )
            isFetchingData = false
        }
    }
}

struct BusinessCardSavedCards_Previews: PreviewProvider {
    static var previews: some View {
        let userData = Binding.constant(UserDataBusiness(
            name: "John Doe",
            profession: "Software Engineer",
            company: "ABC Inc.",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890",
            website: "www.johndoe.com"
        ))

        return BusinessCardSavedCards(userData: userData)
    }
}
