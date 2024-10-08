//
//  NewChatsView.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//


import SwiftUI

struct NewChatsView: View {
    @ObservedObject var session: SessionStore

    var body: some View {
        NavigationView {
            List(session.users) { user in
                NavigationLink(destination: ChatLogView(user: user, session: self.session)) {
                    Text(user.name ?? "Unknown")
                }
            }
            .navigationBarTitle(Text("New Chat"), displayMode: .inline)
        }
        .accentColor(.black)
        .onAppear {
            self.session.fetchUsers(isSavedUsers: true)
        }
    }
}

