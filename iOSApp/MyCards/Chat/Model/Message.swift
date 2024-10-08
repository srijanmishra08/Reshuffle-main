//
//  Message.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//

import UIKit
import FirebaseAuth

struct MessageChat: Hashable {
   // var id : String
    var fromId: String?
    var text : String?
    var timestamp : Int?
    var toId : String?
    var imageUrl : String?
    
    var id : String {
        if fromId == getUID(){
            return toId!
        } else {
            return fromId!
        }
    }
        
    func chatPatnerId() -> String? {
        return fromId == getUID() ? toId : fromId
    }
}
