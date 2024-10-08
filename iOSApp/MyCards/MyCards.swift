import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Firebase
import MapKit
import CodeScanner


class UserDataViewModel: ObservableObject {
    @Published var businessCard: BusinessCard?
    @Published var showAlert: Bool = false
    @Published var showCardSavedAlert: Bool = false
    @Published var showCardAlreadySavedAlert: Bool = false
    private var listener: ListenerRegistration?

    init() {
        fetchData()
    }

    func fetchData() {
        if let userID = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("UserDatabase").document(userID).getDocument { (document, error) in
                if let document = document, document.exists {
                    if let data = document.data() {
                        self.businessCard = BusinessCard(id: UUID(), name: data["name"] as? String ?? "",
                                                         profession: data["profession"] as? String ?? "",
                                                         email: data["email"] as? String ?? "",
                                                         company: data["company"] as? String ?? "",
                                                         role: data["role"] as? String ?? "",
                                                         description: data["description"] as? String ?? "",
                                                         phoneNumber: data["phoneNumber"] as? String ?? "",
                                                         whatsapp: data["whatsapp"] as? String ?? "",
                                                         address: data["address"] as? String ?? "",
                                                         website: data["website"] as? String ?? "",
                                                         linkedIn: data["linkedIn"] as? String ?? "",
                                                         instagram: data["instagram"] as? String ?? "",
                                                         xHandle: data["xHandle"] as? String ?? "", region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                                                         trackingMode: .follow)
                    }
                } else {
                    print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
                }
            }

            listener = Firestore.firestore().collection("UserDatabase").document(userID).addSnapshotListener { (documentSnapshot, error) in
                guard let document = documentSnapshot else {
                    print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                if document.exists {
                    if let data = document.data() {
                        self.businessCard = BusinessCard(id: UUID(), name: data["name"] as? String ?? "",
                                                         profession: data["profession"] as? String ?? "",
                                                         email: data["email"] as? String ?? "",
                                                         company: data["company"] as? String ?? "",
                                                         role: data["role"] as? String ?? "",
                                                         description: data["description"] as? String ?? "",
                                                         phoneNumber: data["phoneNumber"] as? String ?? "",
                                                         whatsapp: data["whatsapp"] as? String ?? "",
                                                         address: data["address"] as? String ?? "",
                                                         website: data["website"] as? String ?? "",
                                                         linkedIn: data["linkedIn"] as? String ?? "",
                                                         instagram: data["instagram"] as? String ?? "",
                                                         xHandle: data["xHandle"] as? String ?? "", region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                                                         trackingMode: .follow)
                    }
                } else {
                    print("User document does not exist.")
                }
            }
        }
    }

    deinit {
        listener?.remove()
    }

    func saveScannedUID(_ scannedUID: String) {
        if let currentUserUID = Auth.auth().currentUser?.uid {
            let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserUID)

            savedUsersRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    var scannedUIDs = document.data()?["scannedUIDs"] as? [String] ?? []

                    if !scannedUID.isEmpty {
                        if scannedUIDs.contains(scannedUID) {
                            DispatchQueue.main.async {
                                self.showCardAlreadySavedAlert = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showCardSavedAlert = true
                            }
                            scannedUIDs.append(scannedUID)
                            savedUsersRef.setData(["scannedUIDs": scannedUIDs], merge: true) { error in
                                if let error = error {
                                    print("Error saving scanned UID: \(error.localizedDescription)")
                                } else {
                                    DispatchQueue.main.async {
                                        self.showCardSavedAlert = true
                                    }
                                }
                            }
                        }
                    }
                } else {
                    let scannedUIDs = !scannedUID.isEmpty ? [scannedUID] : []
                    savedUsersRef.setData(["scannedUIDs": scannedUIDs], merge: true) { error in
                        if let error = error {
                            print("Error saving scanned UID: \(error.localizedDescription)")
                        } else {
                            DispatchQueue.main.async {
                               self.showCardSavedAlert = true
                           }
                        }
                    }
                }
            }
        }
    }
}

struct MyCards: View {
    @EnvironmentObject private var userDataViewModel: UserDataViewModel
    @State private var isChatScreenActive = false
    @State private var isEditCardsActive = false
    @State private var isNotificationsActive = false
    @State private var isImagePickerPresented = false
    @State private var userData = UserDataBusiness(
        name: "John Doe",
        profession: "Software Engineer",
        company: "ABC Inc.",
        email: "john.doe@example.com",
        phoneNumber: "+1234567890",
        website: "www.johndoe.com"
    )
    @State private var userDataCard: UserDataBusinessCard?
    @State private var isPopupActive = false


    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack {
                    Image("Reshufflelogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 50)
                }

                HStack {
                    Text("My Cards")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.leading)

                    Spacer()
                    NavigationLink(destination: NotificationsView().navigationBarBackButtonHidden(true), isActive: $isNotificationsActive) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 25))
                            .padding()
                            .foregroundColor(.black)
                            .onTapGesture {
                                isNotificationsActive = true
                            }
                    }
                }
                .background(Color.white)

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))

                GeometryReader { geometry in
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Spacer()
                            Spacer()
                            Spacer()
                            Spacer()
                            
                            if let businessCard = userDataViewModel.businessCard {
                                CustomCardViewPreview(businessCard: businessCard)
                                    .padding()
                                    .padding(.top)
                                    .padding(.bottom)
                                    .onTapGesture {
                                        isEditCardsActive = true
                                        isPopupActive = true
                                    }
                            } else {
                                Text("Loading...")
                            }
                        }
                        Spacer()
                    }
                }
                .sheet(isPresented: $isPopupActive) {
                                DetailsPopupViewCard()
                            }


                Spacer()
                Spacer()
                Spacer()
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        userDataViewModel.businessCard.map { card in
                            let businessCardPreview = BusinessCardPreview(userData: $userData)
                            businessCardPreview.shareBusinessCard(userData: userData)
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 35))
                                    .foregroundColor(.black)
                            )
                            .padding(.bottom)
                    }

                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 35))
                                    .foregroundColor(.black)
                            )
                            .padding(.bottom)
                    }

                    NavigationLink(destination: EditCards(userDataViewModel: userDataViewModel)) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 35))
                                    .foregroundColor(.black)
                            )
                            .padding(.bottom)
                    }
                }
                .padding()

                Spacer()
                Spacer()
                Spacer()
                Spacer()

                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        QRCodeView(qrCodeData: Auth.auth().currentUser?.uid ?? "")
                            .frame(width: 40, height: 40)
                            .zIndex(1)

                        Spacer()
                    }

                    HStack {
                        Spacer()
                        NavigationLink(destination: ContentViewChat().environmentObject(SessionStore()), isActive: $isChatScreenActive) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20))
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .onTapGesture {
                                    isChatScreenActive = true
                                }
                        }
                        .padding()
                    }

                    

                    Spacer()
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePickerCard(isImagePickerPresented: $isImagePickerPresented)
                    .environmentObject(userDataViewModel)
            }
            .background(Color.white)
            .onAppear {
                fetchUserData()
                fetchUserDataForCard()
            }
            .alert(isPresented: $userDataViewModel.showCardSavedAlert) {
                Alert(
                    title: Text("Card Saved Successfully"),
                    message: Text("This card is saved successfully"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $userDataViewModel.showCardAlreadySavedAlert) {
                Alert(
                    title: Text("Card Already Saved"),
                    message: Text("This card is already saved."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    struct DetailsPopupViewCard: View {
        @EnvironmentObject private var userDataViewModel: UserDataViewModel
        @State private var isFetchingData = false
        @State private var userData: UserDataBusinessCard?

        var body: some View {
            VStack(alignment: .leading) {
                if let userData = userDataViewModel.businessCard {
                    let userDataCard = UserDataBusinessCard(
                        id: Auth.auth().currentUser?.uid, 
                        name: userData.name,
                        profession: userData.profession,
                        company: userData.company,
                        email: userData.email,
                        phoneNumber: userData.phoneNumber,
                        website: userData.website,
                        address: userData.address,
                        linkedIn: userData.linkedIn,
                        instagram: userData.instagram,
                        xHandle: userData.xHandle
                    )
                    let bindingUserDataCard = Binding.constant(userDataCard)
                    BusinessCardSaved(userData: bindingUserDataCard)
                        .padding()
                        .frame(width: 320, height: 380)
                } else {
                    if isFetchingData {
                        ProgressView("Fetching user data...")
                    } else {
                        Text("Error fetching user data.")
                    }
                }
            }
            .onAppear {
                fetchUserData()
            }
        }

        private func fetchUserData() {
            isFetchingData = true

                if let currentUserUID = Auth.auth().currentUser?.uid {
                    Firestore.firestore().collection("UserDatabase").document(currentUserUID).getDocument { documentSnapshot, error in
                        DispatchQueue.main.async {
                            defer {
                                isFetchingData = false
                            }

                            if let error = error {
                                print("Error fetching user details: \(error.localizedDescription)")
                                return
                            }

                            guard let document = documentSnapshot else {
                                print("Document snapshot does not exist")
                                return
                            }

                            do {
                                let user = try document.data(as: UserDataBusinessCard.self)
                                userData = user
                            } catch {
                                print("Error decoding user data: \(error.localizedDescription)")
                            }
                        }
                    }
                } else {
                    print("No user logged in")
                    isFetchingData = false
                }
            }
        }
    

    struct ImagePickerCard: View {
        @Binding var isImagePickerPresented: Bool
        @EnvironmentObject var userDataViewModel: UserDataViewModel
        @State private var scannedCode: String?

        var body: some View {
            VStack {
                if let scannedCode = scannedCode {
                    Text("Scanned Code: \(scannedCode)")
                        .onAppear {
                            isImagePickerPresented = false
                        }
                } else {
                    CodeScannerView(
                        codeTypes: [.qr],
                        completion: { result in
                            switch result {
                            case let .success(scannedResult):
                                let scannedString = scannedResult.string
                                scannedCode = scannedString
                                userDataViewModel.saveScannedUID(scannedString)
                            case .failure:
                                print("Scanning failed")
                            }
                        }
                    )
                }
            }
        }
    }
    private func fetchUserDataForCard() {
        if let currentUserUID = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("UserDatabase").document(currentUserUID).getDocument { (document, error) in
                DispatchQueue.main.async {
                    if let document = document, document.exists {
                        do {
                            let user = try document.data(as: UserDataBusinessCard.self)
                            userDataCard = user
                            print("User data fetched successfully for card: \(userDataCard)")
                        } catch {
                            print("Error decoding user data for card: \(error.localizedDescription)")
                            userDataCard = nil
                        }
                    } else {
                        print("Document does not exist for card")
                        userDataCard = nil
                    }
                }
            }
        } else {
            print("No user logged in for card")
            userDataCard = nil
        }
    }

    private func fetchUserData() {
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
        }
    }
}

struct MyCards_Previews: PreviewProvider {
    static var previews: some View {
        MyCards()
            .environmentObject(UserDataViewModel())
    }
}
