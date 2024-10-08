//
//  ChatsView.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//


import SwiftUI

struct ChatsView: View {
    @ObservedObject var session: SessionStore
    @State var showNewChatsView: Bool = false
    @State private var selectedMessageID: String? = nil
    @State private var isActive: Bool = false

    var body: some View {
        let sortedMessages = session.messages.sorted {
            if let date1 = $0.timestamp, let date2 = $1.timestamp {
                return date1 > date2
            } else if $0.timestamp != nil {
                return true
            } else {
                return false
            }
        }

        List(sortedMessages, id: \.id) { message in
            ZStack {
                ChatViewRow(user: self.session.getUserFromMSG(message), message: message, session: self.session)
                    .onTapGesture {
                        self.selectedMessageID = message.id
                        self.isActive = true
                    }
            }
        }
        .navigationBarTitle(Text("Chats"), displayMode: .large)
        .navigationBarItems(
            trailing: HStack {
                newChatButton
                Button(action: newChat) {
                    Text("New Chat")
                        .foregroundColor(Color.black)
                }
            }
        )
        .sheet(isPresented: $showNewChatsView) {
            NewChatsView(session: self.session)
        }
        .onAppear {
            self.session.fetchUsers(isSavedUsers: false)
        }
        .background(
            NavigationLink(
                destination: ChatLogView(user: self.session.getUserFromMSG(session.messages.first(where: { $0.id == selectedMessageID }) ?? MessageChat()), session: self.session),
                isActive: $isActive
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    var newChatButton: Button<Image> {
        return Button(action: newChat) {
            Image(systemName: "plus")
        }
    }

    func newChat() {
        showNewChatsView = true
    }
}
