import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn

struct SignupView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isOnboardingActive = false
    @ObservedObject var userData: UserData
    @State private var isErrorAlertPresented = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                VStack{
                    Spacer()
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Create a new")
                                .font(.custom("SF Pro", size: 45))
                                .fontWeight(.heavy)
                                .padding(.top,20)
                                .foregroundColor(.black)
                            Text("account")
                                .font(.custom("SF Pro", size: 45))
                                .fontWeight(.heavy)
                                .foregroundColor(Color.gray.opacity(0.8))
                        }
                        .padding()
                        .padding(.bottom,20)
                        Spacer()
                    }
                }

                VStack(spacing: 16) {
                    TextField("Full Name", text: $fullName)
                        .customTextFieldStyle()
                        .padding(EdgeInsets(top: 20, leading: 5, bottom: 10, trailing: 5))
                        .font(.system(size: 20))

                    TextField("Email address", text: $email)
                        .customTextFieldStyle()
                        .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
                        .font(.system(size: 20))
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .customSecureFieldStyle(password: $password, placeholder: "Password")
                        .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
                        .font(.system(size: 20))

                    SecureField("Confirm password", text: $confirmPassword)
                        .customSecureFieldStyle(password: $confirmPassword, placeholder: "Confirm Password")
                        .padding(EdgeInsets(top: 10, leading: 5, bottom: 30, trailing: 5))
                        .font(.system(size: 20))
                }
                .padding(.horizontal)

                NavigationLink(destination: Onboarding(userData: userData).navigationBarBackButtonHidden(true), isActive: $isOnboardingActive) {
                    Button(action: {
                        signUpWithFirebase()
                    }) {
                        Text("Sign up")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: 70)
                            .background(Color.black)
                            .cornerRadius(100)
                    }
                    .padding(.horizontal)
                }
                HStack {
                    Text("Already a member?")

                    NavigationLink(destination: LoginView(userData: userData).navigationBarBackButtonHidden(true)) {
                        Text("Sign In")
                            .foregroundColor(.gray)
                            .fontWeight(.bold)
                    }
                }
                .padding()

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                Image("Reshufflelogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200, height: 80)
                                    .padding()

                Spacer()
            }
            .alert(isPresented: $isErrorAlertPresented) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func signUpWithFirebase() {
        if !isValidEmail(email) {
            errorMessage = "Invalid email format."
            isErrorAlertPresented = true
            return
        }

        if !isValidPassword(password) {
            errorMessage = "Invalid password format. Password must be at least 6 characters."
            isErrorAlertPresented = true
            return
        }
        
        if password != confirmPassword {
                errorMessage = "Password and confirm password do not match."
                isErrorAlertPresented = true
                return
            }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        print("Error signing up: \(error.localizedDescription)")
                        errorMessage = "Invalid email or password. Please try again."
                        isErrorAlertPresented = true
                    } else {
                        print("Successfully signed up!")
                        if let user = authResult?.user {
                            var userData: [String: Any] = [
                                "uid": user.uid,
                                                    "email": user.email ?? "",
                                                    "profilePictureURL": "",
                                                    "username": fullName
                            ]

                            Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                                if let error = error {
                                    print("Error storing user data: \(error.localizedDescription)")
                                    errorMessage = "Failed to store user data."
                                    isErrorAlertPresented = true
                                } else {
                                    print("Successfully signed up and stored user data!")
                                    Firestore.firestore().collection("user-messages").document(user.uid).setData([:]) { error in
                                                if let error = error {
                                                    print("Error creating user-messages document: \(error.localizedDescription)")
                                                    
                                                }
                                        else {
                                                        print("Successfully created user-messages document!")
                                                        isOnboardingActive = true
                                                    }
                                                }
                                    let scannedUIDsData: [String: Any] = [
                                                            "scannedUIDs": []
                                                        ]
                                    Firestore.firestore().collection("SavedUsers").document(user.uid).setData(scannedUIDsData) { error in
                                                if let error = error {
                                                    print("Error creating SacedUsers document: \(error.localizedDescription)")
                                                  
                                                }
                                        else {
                                                        print("Successfully created SavedUsers document!")
                                                        isOnboardingActive = true
                                                    }
                                                }
                                    
                                    let locationsData: [String: Any] = [
                                            "PublicLocation": "ON"
                                        ]
                                    
                                    Firestore.firestore().collection("Location").document(user.uid).setData(locationsData) { error in
                                                if let error = error {
                                                    print("Error creating SacedUsers document: \(error.localizedDescription)")
                                                   
                                                }
                                        else {
                                                        print("Successfully created Locations document!")
                                                        isOnboardingActive = true
                                                    }
                                                }
                                }
                            }
                        } else {
                            errorMessage = "User is nil after sign-up."
                            isErrorAlertPresented = true
                        }
                    }
                }
            }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        SignupView(userData: userData) 
    }
}

