//
//  PhoneConnectivityManager.swift
//  iOSApp
//
//  Created by S on 30/09/24.
//

import Foundation
import WatchConnectivity
import UserNotifications
import os.log
import CryptoKit

// Singleton for handling watch connectivity on the iPhone
class PhoneConnectivityManager: NSObject, WCSessionDelegate {

    static let shared = PhoneConnectivityManager()
    private var session: WCSession?

    private override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - Setup Watch Connectivity
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            os_log("WCSession activated on iPhone", log: OSLog.default, type: .info)
        }
    }

    // MARK: - Handling Received Data
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        os_log("Received message from Watch: %@", log: OSLog.default, type: .info, message.description)

        guard let name = message["name"] as? String, let title = message["title"] as? String, let email = message["email"] as? String else {
            os_log("Invalid data received", log: OSLog.default, type: .error)
            return
        }

        // Process and notify
        let cardInfo = "Contact: \(name), \(title), \(email)"
        notifyUser(cardInfo: cardInfo)
    }

    // MARK: - Sending Local Notification
    private func notifyUser(cardInfo: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Contact Received"
        content.body = cardInfo
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                os_log("Notification error: %@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }

        os_log("Notification sent: %@", log: OSLog.default, type: .info, cardInfo)
    }

    // MARK: - WCSessionDelegate functions
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            os_log("Session activation error: %@", log: OSLog.default, type: .error, error.localizedDescription)
        } else {
            os_log("Session activated with state: %d", log: OSLog.default, type: .info, activationState.rawValue)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        os_log("Session inactive", log: OSLog.default, type: .info)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        os_log("Session deactivated", log: OSLog.default, type: .info)
    }
}
import CryptoKit

func encryptCardData(_ cardInfo: [String: Any]) -> Data? {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: cardInfo, options: [])
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        return sealedBox.combined
    } catch {
        os_log("Encryption error: %@", log: OSLog.default, type: .error, error.localizedDescription)
        return nil
    }
}
