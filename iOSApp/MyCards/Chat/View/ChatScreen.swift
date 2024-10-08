//
//  ChatScreen.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//

import SwiftUI

struct ContentViewChat: View {
    @EnvironmentObject var session : SessionStore
    
    func getUser(){
        session.listen()
    }
    var body: some View {
        Group{
            if (session.session != nil){
                ChatsView(session: self.session)
            }
            else{
                HomeView()
            }
            
        }.onAppear(perform: getUser)
    }
}

struct ContentViewChat_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewChat().environmentObject(SessionStore())
    }
}
