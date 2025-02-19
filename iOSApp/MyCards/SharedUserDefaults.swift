//
//  SharedUserDefaults.swift
//  iOSApp
//
//  Created by S on 19/01/25.
//


// SharedUserDefaults.swift
import Foundation
import WidgetKit

struct SharedUserDefaults {
    static let appGroupIdentifier = "group.com.reshuffle.widget" // Your app group identifier
    static let qrCodeKey = "QRCodeData"
    
    static var shared: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    static func saveQRCode(_ data: String) {
        shared?.set(data, forKey: qrCodeKey)
        shared?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func loadQRCode() -> String {
        shared?.string(forKey: qrCodeKey) ?? "No QR Code Available"
    }
}