//
//  ChatRow.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//

import SwiftUI

class ImageLoaderChat: ObservableObject {
    @Published var image: UIImage?
    @Published var hasLoaded: Bool = false 

    private var urlString: String

    init(urlString: String) {
        self.urlString = urlString
        loadImage()
    }

    func loadImage() {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.image = image
                self.hasLoaded = true
            }
        }.resume()
    }
}



struct ChatRow : View {
    
    var message : MessageChat
    var uid : String
    @Environment(\.imageCache) var cache: ImageCache
    
    var body: some View {
        
        HStack {
            if message.imageUrl != nil{
                if message.fromId == uid {
                    HStack {
                        Spacer()
                        image
                    }.padding(.leading,75)
                } else {
                    HStack {
                        image
                        Spacer()
                    }.padding(.trailing,75)
                }
            } else {
                if message.fromId == uid {
                    HStack {
                        Spacer()
                        Text(message.text ?? "")
                            .modifier(chatModifier(myMessage: true))
                    }.padding(.leading,75)
                } else {
                    HStack {
                        Text(message.text ?? "")
                            .modifier(chatModifier(myMessage: false))
                        Spacer()
                    }.padding(.trailing,75)
                }
            }
        }
    }
    
    private var image: some View {
        AsyncImage(
            url: URL(string: message.imageUrl ?? "")!,
            cache: cache,
            placeholder: ShimmerView().frame(width: 291, height: 291),
            configuration: { $0.resizable().renderingMode(.original) }
        )
            .aspectRatio(contentMode: .fit)
            .frame(idealWidth: 291, idealHeight: 291)
            .cornerRadius(10)
    }
}


struct chatModifier : ViewModifier{
    var myMessage : Bool
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(myMessage ? Color.blue : Color("bg1"))
            .cornerRadius(7)
            .foregroundColor(Color.white)
    }
}


struct ChatViewRow: View {
    var user: UserDataChat
    var message: MessageChat
    var session: SessionStore
    
    @Environment(\.imageCache) var cache: ImageCache
    @StateObject private var imageLoader: ImageLoaderChat
    
    @State private var isChatLogViewPresented = false

    init(user: UserDataChat, message: MessageChat, session: SessionStore) {
        self.user = user
        self.message = message
        self.session = session
        if let profilePictureURL = user.profilePictureURL {
            _imageLoader = StateObject(wrappedValue: ImageLoaderChat(urlString: profilePictureURL))
        } else {
            _imageLoader = StateObject(wrappedValue: ImageLoaderChat(urlString: ""))
        }
    }

    
    var body: some View {
        NavigationLink(destination: ChatLogView(user: user, session: session)) {
            HStack {
                profilePictureView
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(user.name ?? "")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("\(message.timestamp?.timeStringConverter ?? "")")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.black)
                    }
                    Text(message.text ?? "")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if !imageLoader.hasLoaded {
                imageLoader.loadImage()
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            self.isChatLogViewPresented.toggle()
        })
        .background(
            NavigationLink("", destination: ChatLogView(user: user, session: session), isActive: $isChatLogViewPresented)
                .opacity(0)
        )
    }
    
    @ViewBuilder
    private var profilePictureView: some View {
        let imageSize: CGFloat = 50
        
        if let image = imageLoader.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
        }
    }
}
