//
//  ChatLogView.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//

import SwiftUI

struct ChatLogView: View {
    var user: UserDataChat
    @ObservedObject var session: SessionStore
    @State var messages = [MessageChat]()
    @State var write = ""
    @Environment(\.imageCache) var cache: ImageCache
    @State private var showingActionSheet = false
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State var image: Image?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @ObservedObject private var keyboard = KeyboardInfo.shared
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center) {
                    ForEach(messages, id:\.self) { message in
                        ChatRow(message: message, uid: self.session.uid).padding(.vertical, 6)
                    }
                }.frame(width: 374)
            }
            
            Spacer()
            
            HStack {
                cameraButton
                TextField("message...", text: self.$write)
                    .padding(10)
                    .background(Color(red: 233.0/255, green: 234.0/255, blue: 243.0/255))
                    .cornerRadius(25)
                
                Button(action: {
                    if self.write.count > 0 {
                        self.session.sendData(user: self.user, message: self.write)
                        self.write = ""
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(self.write.isEmpty ? Color.gray : Color.blue)
                        .rotationEffect(.degrees(50))
                }
            }.padding()
        }
        .navigationBarTitle(Text(""), displayMode: .inline)
        .navigationBarItems(leading: titleBar)
        .onAppear(perform: getMessages)
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePickerChat(image: self.$inputImage, source: self.sourceType)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text(""), buttons: [
                .default(Text("Choose Photo")) {
                    self.sourceType = .photoLibrary
                    self.showingImagePicker = true
                },
                .default(Text("Take Photo")) {
                    self.sourceType = .camera
                    self.showingImagePicker = true
                },
                .cancel()
            ])
        }
    }
    
    
    private var titleBar: some View {
        HStack {
            if let imageURL = URL(string: user.profilePictureURL ?? "") {
                AsyncImage(
                    url: imageURL,
                    cache: cache,
                    placeholder: Image(systemName: "person.circle.fill"),
                    configuration: { $0.resizable().renderingMode(.original) }
                )
                .aspectRatio(contentMode: .fit)
                .frame(idealHeight: 30 )
                .clipShape(Circle())
                .onTapGesture {
                    // Handle tap gesture
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(idealHeight: 30)
                    .clipShape(Circle())
            }
            
            Text(user.name ?? "").fontWeight(.medium)
        }
        .padding(.leading, 30)
    }
    
    private var cameraButton: Button<Image> {
        Button(action: {
            self.showingActionSheet = true
        }) {
            Image(systemName: "camera")
        }
    }
    
    
    func loadImage() {
        guard let image = inputImage else { return }
        session.uplaodImage(image, forChat: true) { (imageUrl) in
            if let imageUrl = imageUrl {
                let message = MessageChat(fromId: self.session.uid, text: "IMAGE", timestamp: Int(Date().timeIntervalSince1970), toId: self.user.id ?? "", imageUrl: imageUrl)
                
                self.messages.append(message)
                
                self.session.sendData(user: self.user, message: "IMAGE", imageUrl: imageUrl)
            }
        }
    }



    
    func getMessages() {
        session.observeMessages { (dictionary, id) in
            var message = MessageChat()
            
            if let text = dictionary["text"] { message.text = text as? String }
            if let imageUrl = dictionary["imageUrl"] { message.imageUrl = imageUrl as? String }
            message.fromId = dictionary["fromId"] as! String
            message.toId = dictionary["toId"] as! String
            message.timestamp = (dictionary["timestamp"] as? Int)
            
            if message.chatPatnerId() == self.user.id {
                if !self.messages.contains(message) {
                    if let index = self.messages.firstIndex(where: { $0.timestamp ?? 0 > message.timestamp ?? 0 }) {
                        self.messages.insert(message, at: index)
                    } else {
                        self.messages.append(message)
                    }
                    print("Message received and appended:", message)
                }
            } else {
                print("Message ignored:", message)
            }
        }
    }
}
