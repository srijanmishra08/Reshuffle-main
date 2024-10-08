//
//  SessionStore.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//

import SwiftUI
import Firebase
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class SessionStore: ObservableObject {
    
    let db = Firestore.firestore()
    
    var didChange = PassthroughSubject<SessionStore, Never>()
    
    let uid = Auth.auth().currentUser?.uid ?? "uid"
    
    @Published var session: UserChat? {
        didSet {
            self.didChange.send(self)
        }
    }
    
    @Published var users = [UserDataChat]()
    @Published var messages = [MessageChat]()
    @Published var messagesDictionary = [String: MessageChat]()
    
    var handle: AuthStateDidChangeListenerHandle?
    
    func listen() {
        handle = Auth.auth().addStateDidChangeListener({ [weak self] (auth, user) in
            guard let self = self else { return }

            if let user = user {
                print("user state changed")
                self.session = UserChat(uid: user.uid, email: user.email)
                
                // Determine whether to fetch users from 'SavedUsers' or all users
                let isSavedUsers = false // Or determine based on your logic
                
                self.fetchUsers(isSavedUsers: isSavedUsers)
                self.observeUserMessages()
            } else {
                self.session = nil
            }
        })
    }

    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.session = nil
            self.users = []
            self.messages = [MessageChat]()
            self.messagesDictionary = [String: MessageChat]()
        } catch {
            print("Error signing out")
        }
    }
    
    func unbind() {
        if let handle = handle {
            print("unbind")
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    deinit {
        unbind()
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let reference = db.collection("user-messages").document(uid)
        
        reference.addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error observing user-messages: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.data()?.forEach({ (key, value) in
                let messageId = key
                
                let messagesReference = self.db.collection("messages").document(messageId)
                
                messagesReference.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let dictionary = document.data()!
                        
                        var message = MessageChat()
                        
                        message.text = dictionary["text"] as? String
                        message.imageUrl = dictionary["imageUrl"] as? String
                        message.fromId = dictionary["fromId"] as! String
                        message.toId = dictionary["toId"] as! String
                        message.timestamp = dictionary["timestamp"] as? Int ?? 0
                        
                        if let chatPatnerId = message.chatPatnerId() {
                            self.messagesDictionary[chatPatnerId] = message
                            self.messages = Array(self.messagesDictionary.values)
                            
                            // Sort messages Array
                            self.messages.sort { (message1, message2) -> Bool in
                                let timestamp1 = message1.timestamp ?? 0
                                let timestamp2 = message2.timestamp ?? 0
                                return timestamp1 > timestamp2
                            }
                        }
                    }
                }
            })
        }
    }
    
    func observeMessages(completion: @escaping ([String: Any], String) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userMessagesRef = db.collection("user-messages").document(uid)
        
        userMessagesRef.addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error observing user-messages for messages: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.data()?.forEach({ (key, value) in
                let messageId = key
                
                let messagesRef = self.db.collection("messages").document(messageId)
                
                messagesRef.getDocument { (document, error) in
                    guard let document = document, document.exists else { return }
                    let dictionary = document.data()!
                    
                    completion(dictionary, messageId)
                }
            })
        }
    }
    
    func fetchUsers(isSavedUsers: Bool) {
        if isSavedUsers {
            guard let currentUserUID = Auth.auth().currentUser?.uid else {
                print("Current user UID is nil")
                return
            }
            
            let savedUsersRef = db.collection("SavedUsers").document(currentUserUID)
            
            savedUsersRef.getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching SavedUsers document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("SavedUsers document does not exist")
                    return
                }
                
                let data = document.data() ?? [:]
                
                if let scannedUIDs = data["scannedUIDs"] as? [String] {
                    // Fetch user details for each scanned UID
                    self.users = []
                    for scannedUID in scannedUIDs {
                        self.db.collection("users").document(scannedUID).getDocument { (userDocument, userError) in
                            if let userError = userError {
                                print("Error fetching user document for UID \(scannedUID): \(userError.localizedDescription)")
                                return
                            }
                            
                            guard let userDocument = userDocument, userDocument.exists else {
                                print("User document for UID \(scannedUID) does not exist")
                                return
                            }
                            
                            let userData = userDocument.data() ?? [:]
                            let name = userData["username"] as? String ?? "Unknown"
                            let email = userData["email"] as? String
                            let profileImageUrl = userData["profilePictureURL"] as? String
                            
                            let user = UserDataChat(email: email, name: name, profilePictureURL: profileImageUrl, id: scannedUID)
                            
                            DispatchQueue.main.async {
                                self.users.append(user)
                            }
                        }
                    }
                }
            }
        } else {
            // Fetch all users from the general 'users' collection
            db.collection("users").getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching users: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("No users found")
                    return
                }
                
                self.users = snapshot.documents.compactMap { document in
                    let data = document.data()
                    let id = document.documentID
                    let name = data["username"] as? String ?? "Unknown"
                    let email = data["email"] as? String
                    let profileImageUrl = data["profilePictureURL"] as? String
                    
                    return UserDataChat(email: email, name: name, profilePictureURL: profileImageUrl, id: id)
                }
            }
        }
    }

    
    func createUser(user: UserDataChat) {
        let param = ["username": user.name, "email": user.email, "profilePictureURL": user.profilePictureURL]
        db.collection("users").document(getUID()).setData(param) { error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func getUserFromMessage(_ message: MessageChat, completion: @escaping (UserDataChat) -> ()) {
        guard let chatPatnerId = message.chatPatnerId() else { return }
        
        db.collection("users").document(chatPatnerId).getDocument { (snapshot, error) in
            guard let snapshot = snapshot, snapshot.exists else { return }
            
            let data = snapshot.data()!
            var user = UserDataChat()
            user.name = data["username"] as! String
            user.email = data["email"] as! String
            user.profilePictureURL = data["profilePictureURL"] as! String
            user.id = chatPatnerId
            
            completion(user)
        }
    }
    
    func getUserFromMSG(_ message: MessageChat) -> UserDataChat {
        if let chatPatnerId = message.chatPatnerId() {
            if let user = self.users.first(where: { $0.id == chatPatnerId }) {
                return user
            }
        }
        return UserDataChat()
    }
    
    func sendData(user: UserDataChat, message: String, imageUrl: String? = nil) {
        let messagesCollection = db.collection("messages")
        
        var newMessageRef: DocumentReference?
        
        // Add document to "messages" collection
        newMessageRef = messagesCollection.addDocument(data: [
            "text": message,
            "toId": user.id!,
            "fromId": Auth.auth().currentUser!.uid,
            "timestamp": Int(NSDate().timeIntervalSince1970)
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            } else {
                // Successfully added message to "messages" collection
                guard let messageId = newMessageRef?.documentID else {
                    print("Error: Could not get message ID")
                    return
                }
                
                // Update user's "user-messages" reference
                let userMessagesRef = self.db.collection("user-messages").document(Auth.auth().currentUser!.uid)
                userMessagesRef.updateData([messageId: "a"]) { error in
                    if let error = error {
                        print("Error updating user's user-messages reference: \(error.localizedDescription)")
                    }
                }
                
                // Update recipient's "user-messages" reference
                let recipientUserMessagesReference = self.db.collection("user-messages").document(user.id!)
                recipientUserMessagesReference.getDocument { (document, error) in
                    if let error = error {
                        print("Error getting recipient's user-messages reference: \(error.localizedDescription)")
                    } else if document == nil {
                        // If the document doesn't exist, create it
                        recipientUserMessagesReference.setData([messageId: "a"]) { error in
                            if let error = error {
                                print("Error creating recipient's user-messages reference: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        // If the document exists, update it
                        recipientUserMessagesReference.updateData([messageId: "a"]) { error in
                            if let error = error {
                                print("Error updating recipient's user-messages reference: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    // If imageUrl is provided, update it in the "messages" collection
                    if let imageUrl = imageUrl {
                        newMessageRef?.updateData(["imageUrl": imageUrl]) { error in
                            if let error = error {
                                print("Error updating imageUrl: \(error.localizedDescription)")
                            } else {
                                // Update local messagesDictionary and messages array
                                let timestamp = Int(NSDate().timeIntervalSince1970)
                                let newMessage = MessageChat(fromId: Auth.auth().currentUser!.uid, text: message, timestamp: timestamp, toId: user.id!, imageUrl: imageUrl)
                                
                                if let chatPatnerId = newMessage.chatPatnerId() {
                                    // Check if the message already exists in messagesDictionary
                                    if let existingMessage = self.messagesDictionary[chatPatnerId] {
                                        // Update the existing message with new data using subscript
                                        self.messagesDictionary[chatPatnerId]?.text = newMessage.text
                                        self.messagesDictionary[chatPatnerId]?.imageUrl = newMessage.imageUrl
                                        self.messagesDictionary[chatPatnerId]?.timestamp = newMessage.timestamp
                                    } else {
                                        // If the message doesn't exist, add it to messagesDictionary
                                        self.messagesDictionary[chatPatnerId] = newMessage
                                    }
                                    
                                    // Update messages array
                                    self.messages = Array(self.messagesDictionary.values)
                                    
                                    // Sort messages Array
                                    self.messages.sort { (message1, message2) -> Bool in
                                        let timestamp1 = message1.timestamp ?? 0
                                        let timestamp2 = message2.timestamp ?? 0
                                        return timestamp1 > timestamp2
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func updateProfileImage(url: String) {
        let ref = db.collection("users").document(session?.uid ?? "uid")
        ref.updateData(["imageUrl": url])
    }
    
    func createProfile(_ profileImage: UIImage) {
        uplaodImage(profileImage) { (url) in
            if let url = url {
                self.updateProfileImage(url: url)
            }
        }
    }
    
    func uplaodImage(_ profileImage: UIImage, forChat: Bool = false, completion: @escaping (String?) -> ()) {
        let ref = Storage.storage().reference()
        var storageRef: StorageReference
        
        if forChat {
            // If uploading image for chat, create a separate folder for chat images
            storageRef = ref.child("chat_images").child("\(UUID().uuidString).jpg")
        } else {
            // If not for chat, upload to the default "profile_images" folder
            storageRef = ref.child("profile_images").child("\(uid).jpg")
        }
        
        if let uploadData = profileImage.jpegData(compressionQuality: 0.2) {
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(nil)
                    print(error.localizedDescription)
                } else {
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            completion(nil)
                            print(error.localizedDescription)
                        } else {
                            completion(url?.absoluteString ?? "invalid")
                        }
                    }
                }
            }
        }
    }
}
struct UserChat {
    var uid : String
    var email : String?
    
    init(uid:String,email:String?){
        self.uid = uid
        self.email = email
    }
}
