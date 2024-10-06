//
//  GestureManager.swift
//  iOSApp
//
//  Created by S on 30/09/24.
//

import Foundation
import CoreMotion
import WatchConnectivity
import os.log

// Enum for different gesture types
enum GestureError: Error {
    case insufficientMotionData
    case connectivityFailure(String)
}

// Gesture detection and handling for WatchOS
class GestureManager: NSObject {
    private let motionManager = CMMotionManager()
    private var session: WCSession?

    // Singleton pattern to ensure single instance of GestureManager
    static let shared = GestureManager()

    private override init() {
        super.init()
        setupWatchConnectivity()
        os_log("GestureManager initialized", log: OSLog.default, type: .info)
    }

    // MARK: - Watch Connectivity Setup
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Gesture Detection Logic
    func startMonitoringGestures() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw GestureError.insufficientMotionData
        }

        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motionData, error) in
            guard let self = self else { return }
            if let motionData = motionData {
                self.handleMotionData(motionData)
            } else if let error = error {
                os_log("Motion error: %@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
    }

    // Gesture recognition logic based on motion data
    private func handleMotionData(_ motionData: CMDeviceMotion) {
        let rotationRate = motionData.rotationRate
        let acceleration = motionData.userAcceleration

        // Customize the gesture detection
        if rotationRate.x > 3.0 && acceleration.x > 1.5 {
            // Gesture recognized; send card
            do {
                try sendCardData()
            } catch let error {
                os_log("Error in sending card data: %@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
    }

    // MARK: - Sending Card Data
    private func sendCardData() throws {
        let cardInfo: [String: Any] = [
            "name": "John Doe",
            "title": "Software Engineer",
            "email": "john@example.com"
        ]

        // Ensure that the session is reachable
        guard let session = session, session.isReachable else {
            throw GestureError.connectivityFailure("Session unreachable")
        }

        session.sendMessage(cardInfo, replyHandler: nil, errorHandler: { error in
            os_log("Failed to send message: %@", log: OSLog.default, type: .error, error.localizedDescription)
        })

        os_log("Card info sent: %@", log: OSLog.default, type: .info, cardInfo.description)
    }
}

// MARK: - WCSessionDelegate Implementation
extension GestureManager: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        <#code#>
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        <#code#>
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            os_log("WCSession activation error: %@", log: OSLog.default, type: .error, error.localizedDescription)
        } else {
            os_log("WCSession activated", log: OSLog.default, type: .info)
        }
    }
}

