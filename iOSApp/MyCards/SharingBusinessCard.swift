//
//  SharingBusinessCard.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 01/03/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Firebase
import PassKit

struct UserDataBusiness: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var profession: String
    var company: String
    var email: String
    var phoneNumber: String
    var website: String
}

struct BusinessCardPreview: View {
    @State private var sharedImage: UIImage?
    @StateObject private var userDataViewModel = UserDataViewModel()
    @Binding var userData: UserDataBusiness
    @State private var isFetchingData = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image("LOGO")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 50)
                VStack(alignment: .center, spacing: 10) {
                    Text(userData.name)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(userData.profession)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(userData.company)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.white)
                        Text(userData.email)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.white)
                        Text(userData.phoneNumber)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.white)
                        Text(userData.website)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    VStack {
                        QRCodeView(qrCodeData: userData.id ?? "")
                            .frame(width: 100, height: 100)
                            .scaledToFit()
                            .zIndex(1)
                    }.padding(.bottom,30)
                }
                .padding()
                .background(Color.black)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 2)
                )
            }
            .padding(20)
            .onAppear {
                fetchUserData()
            }
            .onChange(of: userData) { _ in

                shareBusinessCard(userData: userData)

            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    shareBusinessCard(userData: userData)

                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
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

    
    func shareBusinessCard(userData: UserDataBusiness) {
        if !isFetchingData {
            print("Sharing business card...")
            let image = generateBusinessCardImage(userData: userData)
            guard let sharedImage = image else {
                print("Image generation failed")
                return
            }
            
            var activityItems: [Any] = [sharedImage]
            
            // Check if PassKit is available
            if PKAddPassesViewController.canAddPasses() {
                // Generate a pass
                if let pass = generatePass(for: userData) {
                    activityItems.append(pass)
                } else {
                    print("Pass generation failed")
                }
            }
            
            // Create the activity view controller
            let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            
            // Present the activity view controller
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                activityViewController.popoverPresentationController?.sourceView = viewController.view
                viewController.present(activityViewController, animated: true, completion: nil)
            } else {
                print("Unable to present activity view controller")
            }
        } else {
            print("Data is still being fetched, cannot share")
        }
    }

    private func generatePass(for userData: UserDataBusiness) -> PKPass? {
        // Create pass content dictionary
        var passContent: [String: Any] = [
            "name": userData.name,
            "profession": userData.profession,
            "company": userData.company,
            "email": userData.email,
            "phone": userData.phoneNumber,
            "website": userData.website
        ]
        
        // Serialize pass content to JSON data
        do {
            let passContentData = try JSONSerialization.data(withJSONObject: passContent, options: [])
            
            // Initialize PKPass with pass content data
            let pass = try PKPass(data: passContentData)
            return pass
        } catch {
            print("Failed to create PKPass: \(error)")
            return nil
        }
    }

    private func generateBusinessCardImage(userData: UserDataBusiness) -> UIImage? {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 600))
        let businessCardView = BusinessCardPreview(userData: $userData) // Pass user data to the view
        let hostingController = UIHostingController(rootView: businessCardView)
        hostingController.view.frame = containerView.bounds
        containerView.addSubview(hostingController.view)
        
        let renderer = UIGraphicsImageRenderer(size: containerView.bounds.size)
        let image = renderer.image { _ in
            containerView.drawHierarchy(in: containerView.bounds, afterScreenUpdates: true)
        }
        
        return image
    }

    
    private func userDataDetailsString(_ userData: UserDataBusiness) -> String {
        // Format the user data into a string
        var userDetailsString = ""
        userDetailsString += "Name: \(userData.name)\n"
        userDetailsString += "Profession: \(userData.profession)\n"
        userDetailsString += "Company: \(userData.company)\n"
        userDetailsString += "Email: \(userData.email)\n"
        userDetailsString += "Phone Number: \(userData.phoneNumber)\n"
        userDetailsString += "Website: \(userData.website)\n"
        return userDetailsString
    }
}

struct BusinessCardPreview_Previews: PreviewProvider {
    static var previews: some View {
        let userData = Binding.constant(UserDataBusiness(
            name: "John Doe",
            profession: "Software Engineer",
            company: "ABC Inc.",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890",
            website: "www.johndoe.com"
        ))

        return BusinessCardPreview(userData: userData)
    }
}

