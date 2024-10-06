import SwiftUI
import Firebase
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

struct SettingsView: View {
    @State private var profileCompletion = 60
    @State private var lockscreenWidgetEnabled = true
    @State private var nfcEnabled = true
    @State private var appleWatchWidgetEnabled = false
    @State private var pushNotificationsEnabled = true
    @State private var showingContacts = false
    @State private var userName: String?
    @State private var selectedImage: UIImage?
    @State private var profileImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var publicLocationEnabled = false
    @State private var profilePictureURL: String?
    @State private var publicLocationLoading = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Complete Your Profile")) {
                    HStack {
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                }
                        }
                        
                        VStack(alignment: .leading) {
                            Text(userName ?? "Loading...")
                                .font(.headline)
                            Text("\(profileCompletion)% Profile Completed")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                

                    
                    Section(header: Text("Location"),footer: Text("Turning on Public Location allows your card to be discovered by all Reshuffle users. It also enables them to save your card. If you want your card to remain private, turn off Public Location.")
                        .font(.caption)) {
                        if publicLocationLoading {
                            ProgressView()
                        } else {
                            Toggle("Public Location", isOn: $publicLocationEnabled)
                                .onChange(of: publicLocationEnabled) { newValue in
                                    updatePublicLocation(newValue)
                                }
                        }
                    }
                    
                Section(header: Text("Widgets")) {
                    Toggle("Lockscreen Widget", isOn: $lockscreenWidgetEnabled)

                    Toggle("NFC", isOn: $nfcEnabled)

                    Toggle("Apple Watch Widget", isOn: $appleWatchWidgetEnabled)
                }

                Section(header: Text("Notifications")) {
                    Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                }

                

                NavigationLink(destination: ContactsView(), isActive: $showingContacts) {
                    Text("Invite Contacts")
                        .onTapGesture {
                            showingContacts = true
                        }
                }

                Section {
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            UserDefaults.standard.set(false, forKey: "isLoggedIn")
                            let userData = UserData()
                            UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: LoginView(userData: userData))
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                                            }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        deleteAccount()
                    }) {
                        Text("Delete account")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isImagePickerPresented, onDismiss: {
            }) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
        .onAppear {
            fetchProfilePictureURL()
            fetchPublicLocation()
            if let userID = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("users").document(userID).getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()
                        userName = data?["username"] as? String
                    } else {
                        print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
    private func uploadProfilePicture(_ image: UIImage) {
            guard let userID = Auth.auth().currentUser?.uid else { return }

            let storageRef = Storage.storage().reference().child("profile_images").child("\(userID).jpg")
            if let uploadData = image.jpegData(compressionQuality: 0.2) {
                storageRef.putData(uploadData, metadata: nil) { (_, error) in
                    if let error = error {
                        print("Error uploading profile picture: \(error.localizedDescription)")
                    } else {
                        storageRef.downloadURL { (url, error) in
                            if let error = error {
                                print("Error getting download URL: \(error.localizedDescription)")
                            } else if let url = url {
                                let urlString = url.absoluteString
                                Firestore.firestore().collection("users").document(userID).updateData(["profilePictureURL": urlString]) { error in
                                    if let error = error {
                                        print("Error updating profile picture URL: \(error.localizedDescription)")
                                    } else {
                                        print("Profile picture URL updated successfully")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    
    
    private func fetchPublicLocation() {
            publicLocationLoading = true
            if let userID = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("Location").document(userID).getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()
                        if let publicLocation = data?["PublicLocation"] as? String {
                            publicLocationEnabled = (publicLocation == "ON")
                        }
                    } else {
                        print("Public Location document not found: \(error?.localizedDescription ?? "Unknown error")")
                    }
                    publicLocationLoading = false
                }
            }
        }
    private func fetchProfilePicture() {
        guard let profilePictureURL = profilePictureURL else { return }
        guard let url = URL(string: profilePictureURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch profile picture:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            DispatchQueue.main.async {
                self.profileImage = UIImage(data: data)
            }
        }.resume()
    }

    private func fetchProfilePictureURL() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error fetching profile picture URL: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                profilePictureURL = data?["profilePictureURL"] as? String
                fetchProfilePicture()
            }
        }
    }


        private func updatePublicLocation(_ newValue: Bool) {
            let locationValue = newValue ? "ON" : "OFF"
            if let userID = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("Location").document(userID).setData(["PublicLocation": locationValue]) { error in
                    if let error = error {
                        print("Error updating Public Location: \(error.localizedDescription)")
                    }
                }
            }
        }

    private func deleteAccount() {
        if let userID = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(userID).delete { error in
                if let error = error {
                    print("Error deleting user data: \(error.localizedDescription)")
                } else {
                    Auth.auth().currentUser?.delete { error in
                        if let error = error {
                            print("Error deleting user account: \(error.localizedDescription)")
                        } else {
                            let userData = UserData()
                            UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: SignupView(userData: userData))
                        }
                    }
                }
            }
        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        var profilePictureURL: String?

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                uploadProfilePicture(uiImage)
            }

            parent.presentationMode.wrappedValue.dismiss()
        }


        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }

        private func uploadProfilePicture(_ image: UIImage) {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            
            let storageRef = Storage.storage().reference().child("profile_images").child("\(userID).jpg")
            if let uploadData = image.jpegData(compressionQuality: 0.2) {
                storageRef.putData(uploadData, metadata: nil) { (_, error) in
                    if let error = error {
                        print("Error uploading profile picture: \(error.localizedDescription)")
                    } else {
                        storageRef.downloadURL { (url, error) in
                            if let error = error {
                                print("Error getting download URL: \(error.localizedDescription)")
                            } else if let url = url {
                                let urlString = url.absoluteString
                                Firestore.firestore().collection("users").document(userID).updateData(["profilePictureURL": urlString]) { error in
                                    if let error = error {
                                        print("Error updating profile picture URL: \(error.localizedDescription)")
                                    } else {
                                        print("Profile picture URL updated successfully")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}


struct ContactsView: View {
    var body: some View {
        Text("Contacts Screen")
            .navigationTitle("Contacts")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
