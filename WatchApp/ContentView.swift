import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var isEnabled = false
    @State private var showQRCode = false
    @State private var businessCard: BusinessCard?
    
    var body: some View {
        VStack {
            if isEnabled {
                if showQRCode {
                    QRCodeView(businessCard: businessCard)
                } else {
                    HandshakeView(businessCard: businessCard)
                }
                
                Button(action: {
                    showQRCode.toggle()
                }) {
                    Text(showQRCode ? "Show Handshake" : "Show QR Code")
                }
            } else {
                Text("Apple Watch Widget is disabled")
            }
        }
        .onAppear {
            setupWatchConnectivity()
            loadBusinessCard()
        }
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = WatchSessionDelegate.shared
            session.activate()
        }
    }
    
    private func loadBusinessCard() {
        // Load business card data from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "businessCard"),
           let decodedCard = try? JSONDecoder().decode(BusinessCard.self, from: data) {
            businessCard = decodedCard
        }
    }
}

class WatchSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let enabled = userInfo["appleWatchWidgetEnabled"] as? Bool {
            DispatchQueue.main.async {
                UserDefaults.standard.set(enabled, forKey: "appleWatchWidgetEnabled")
                NotificationCenter.default.post(name: .appleWatchWidgetStatusChanged, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let appleWatchWidgetStatusChanged = Notification.Name("appleWatchWidgetStatusChanged")
}