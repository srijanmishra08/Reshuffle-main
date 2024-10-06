//
//  Constants.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

//MARK: -  function to get uid
internal func getUID() -> String {
    let uid = Auth.auth().currentUser?.uid
    return uid ?? "notFound"
}


public func debugLog(message: String) {
    #if DEBUG
    debugPrint("=======================================")
    debugPrint(message)
    debugPrint("=======================================")
    #endif
}
