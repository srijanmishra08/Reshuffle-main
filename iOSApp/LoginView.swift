import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct BackgroundColorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 12))
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
    }
}

extension TextField {
    func customTextFieldStyle() -> some View {
        self.modifier(BackgroundColorModifier())
    }
}

struct CustomSecureFieldStyle: TextFieldStyle {
    @Binding var password: String
    @State private var isPasswordVisible = false
    var placeholder: String
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack(alignment: .trailing) {
            if isPasswordVisible {
                TextField(placeholder, text: $password)
                    .font(.system(size: 20))
            } else {
                SecureField(placeholder, text: $password)
                    .font(.system(size: 20))
            }
            
            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.black)
                    .padding(.trailing, 10)
            }
            .padding(.trailing, 10)
        }
    }
}

extension SecureField {
    func customSecureFieldStyle(password: Binding<String>, placeholder: String) -> some View {
        self.textFieldStyle(CustomSecureFieldStyle(password: password, placeholder: placeholder))
            .modifier(BackgroundColorModifier())
    }
}




struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSignupActive = false
    @State private var isOnboardingActive = false
    @ObservedObject var userData: UserData
    @State private var isErrorAlertPresented = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome to")
                                    .font(.custom("SF Pro", size: 45))
                                    .fontWeight(.heavy)
                                    .foregroundColor(.black)
                                Text("Reshuffle")
                                    .font(.custom("SF Pro", size: 45))
                                    .fontWeight(.heavy)
                                    .foregroundColor(Color.gray.opacity(0.8))
                            }
                            .padding()
                            .padding(.bottom,20)
                    Spacer()
                        }

                VStack(spacing: 16) {
                    TextField("Email or username", text: $email)
                        .customTextFieldStyle()
                        .padding(EdgeInsets(top: 30, leading: 5, bottom: 15, trailing: 5))
                        .font(.system(size: 20))
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .customSecureFieldStyle(password: $password, placeholder: "Password")
                        .padding(EdgeInsets(top: 15, leading: 5, bottom: 30, trailing: 5))
                        .font(.system(size: 20))
                }
                .padding(.horizontal)

                HStack {
                    Spacer()
                    Button(action: {
                        resetPassword()
                    }) {
                        Text("Forgot password?")
                            .foregroundColor(.gray)
                    }
                    .padding()
                }

                NavigationLink(destination: FirstPage().navigationBarBackButtonHidden(true)) {
                    Button(action: {
                        loginWithFirebase()
                    }) {
                        Text("Log in")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: 70)
                            .background(Color.black)
                            .cornerRadius(100)
                    }
                    .padding(.horizontal)
                }
                HStack {
                    Text("Don’t have an account?")

                    NavigationLink(destination: SignupView(userData: userData).navigationBarBackButtonHidden(true)) {
                        EmptyView()
                    }
                    .hidden()

                    Button(action: {
                        isSignupActive = true
                    }) {
                        Text(" Sign up")
                            .foregroundColor(.gray)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                
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
        .onAppear {
            if !isLoggedIn {
                isOnboardingActive = false
            }
        }
    }

    private func loginWithFirebase() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                errorMessage = "Invalid email or password. Please try again."
                isErrorAlertPresented = true
            } else {
                print("Successfully signed in!")
                isLoggedIn = true

                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                withAnimation {
                    isOnboardingActive = true
                }
            }
        }
    }

    private func loginWithApple() {
        print("Log in using Apple")
    }

    private func loginWithGoogle() {
        print("Log in using Google")
    }

    private func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Error sending password reset email: \(error.localizedDescription)")
                errorMessage = "Error sending password reset email. Please try again."
                isErrorAlertPresented = true
            } else {
                print("Password reset email sent successfully!")
                errorMessage = "Password reset email sent successfully. Check your inbox."
                isErrorAlertPresented = true
            }
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        LoginView(userData: userData)
    }
}


