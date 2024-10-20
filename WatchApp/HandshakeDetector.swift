import Foundation
import CoreMotion

class HandshakeDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    
    @Published var isHandshakeDetected = false
    
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            if let data = self?.motionManager.accelerometerData {
                self?.detectHandshake(data: data)
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        timer?.invalidate()
    }
    
    private func detectHandshake(data: CMAccelerometerData) {
        let threshold: Double = 2.0
        if abs(data.acceleration.x) > threshold &&
           abs(data.acceleration.y) > threshold &&
           abs(data.acceleration.z) > threshold {
            DispatchQueue.main.async {
                self.isHandshakeDetected = true
            }
        }
    }
}

struct HandshakeView: View {
    @StateObject private var handshakeDetector = HandshakeDetector()
    let businessCard: BusinessCard?
    
    var body: some View {
        VStack {
            Image(systemName: "hand.wave")
                .font(.system(size: 50))
                .rotationEffect(.degrees(handshakeDetector.isHandshakeDetected ? 20 : -20))
                .animation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: handshakeDetector.isHandshakeDetected)
            
            Text("Shake hands to share")
                .font(.caption)
        }
        .onAppear {
            handshakeDetector.startMonitoring()
        }
        .onDisappear {
            handshakeDetector.stopMonitoring()
        }
        .onChange(of: handshakeDetector.isHandshakeDetected) { newValue in
            if newValue {
                shareBusinessCard()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    handshakeDetector.isHandshakeDetected = false
                }
            }
        }
    }
    
    private func shareBusinessCard() {
        guard let businessCard = businessCard else { return }
        
        // Implement sharing logic here, e.g., using WatchConnectivity to send the card to the paired iPhone
        if WCSession.isSupported() {
            let session = WCSession.default
            session.transferUserInfo(["sharedBusinessCard": businessCard.dictionary])
        }
    }
}