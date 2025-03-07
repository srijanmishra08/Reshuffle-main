import Foundation
import CoreNFC
import FirebaseFirestore
import FirebaseAuth
import UIKit

class NFCBusinessCardSharingViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isNFCSharing = false
    @Published var nfcStatus: String = ""
    @Published var receivedCardUserID: String?
    @Published var isNFCSupported: Bool = false
    
    // MARK: - Private Properties
    private var nfcSession: NFCNDEFReaderSession?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkNFCAvailability()
    }
    
    // MARK: - NFC Capability Checking
    
    /// Check if NFC is available on this device
    func checkNFCAvailability() {
        // Basic capability check - using property for UI updates
        isNFCSupported = NFCNDEFReaderSession.readingAvailable
        
        if !isNFCSupported {
            nfcStatus = "NFC is not available on this device"
            print("NFC capability not available on this device")
        } else {
            // Additional OS version-specific compatibility checks
            if #available(iOS 18, *) {
                print("Running on iOS 18 or newer - full NFC support")
            } else if #available(iOS 17.6, *) {
                print("Running on iOS 17.6 - standard NFC support")
            } else if #available(iOS 17.0, *) {
                print("Running on iOS 17.0 - basic NFC support")
            } else {
                print("Running on older iOS - limited NFC support")
            }
        }
    }
    
    // MARK: - NFC Session Management
    
    /// Start NFC sharing/reading session with error handling
    func startNFCSharing() {
        guard isNFCSupported else {
            nfcStatus = "NFC is not supported on this device"
            return
        }
        
        do {
            // Create and configure session
            nfcSession = NFCNDEFReaderSession(
                delegate: self,
                queue: DispatchQueue.main,
                invalidateAfterFirstRead: true
            )
            
            // Configure alerting
            nfcSession?.alertMessage = "Hold your device near another phone to share your business card"
            nfcSession?.begin()
            
            isNFCSharing = true
            nfcStatus = "Ready to share business card..."
        } catch {
            isNFCSharing = false
            nfcStatus = "Failed to start NFC: \(error.localizedDescription)"
            print("NFC session error: \(error)")
        }
    }
    
    /// Prepare NFC message with user's card data
    func prepareNFCMessage() -> NFCNDEFMessage? {
        guard let currentUser = Auth.auth().currentUser else {
            nfcStatus = "User not logged in"
            return nil
        }
        
        // Create a properly formatted NDEF record
        let userIDString = currentUser.uid
        guard let userIDData = userIDString.data(using: .utf8) else {
            nfcStatus = "Failed to encode user data"
            return nil
        }
        
        // Create text record with proper format
        let payload = NFCNDEFPayload.wellKnownTypeTextPayload(
            string: userIDString,
            locale: Locale.current
        ) ?? NFCNDEFPayload(
            format: .nfcWellKnown,
            type: "T".data(using: .utf8)!,
            identifier: "reshufflecard".data(using: .utf8)!,
            payload: userIDData
        )
        
        return NFCNDEFMessage(records: [payload])
    }
    
    // MARK: - Business Card Operations
    
    /// Share business card via NFC
    func shareBusinessCard() {
        guard isNFCSupported else {
            offerAlternativeSharingMethods()
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            nfcStatus = "User must be logged in to share card"
            return
        }
        
        startNFCSharing()
    }
    
    /// Save received card to Firestore with error handling
    func saveReceivedCard(_ receivedUserID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            nfcStatus = "Current user not authenticated"
            return
        }
        
        let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserID)
        
        savedUsersRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.nfcStatus = "Error retrieving saved cards: \(error.localizedDescription)"
                return
            }
            
            var scannedUIDs = document?.data()?["scannedUIDs"] as? [String] ?? []
            
            if !scannedUIDs.contains(receivedUserID) {
                scannedUIDs.append(receivedUserID)
                
                savedUsersRef.setData(["scannedUIDs": scannedUIDs], merge: true) { error in
                    if let error = error {
                        self.nfcStatus = "Failed to save card: \(error.localizedDescription)"
                    } else {
                        self.nfcStatus = "Card received and saved successfully"
                        self.notifyUserOfSuccess()
                    }
                }
            } else {
                self.nfcStatus = "Card already in your collection"
            }
        }
    }
    
    // MARK: - Alternative Methods
    
    /// Offer alternative sharing methods for devices without NFC
    private func offerAlternativeSharingMethods() {
        nfcStatus = "NFC not available. Using alternative sharing method."
        // Implementation for alternative sharing could go here
        // For example, QR code generation or sharing link
    }
    
    /// Notify user of successful card exchange
    private func notifyUserOfSuccess() {
        // Could implement custom UI notification here
        print("Business card exchange successful")
    }
}

// MARK: - NFCNDEFReaderSessionDelegate Implementation

extension NFCBusinessCardSharingViewModel: NFCNDEFReaderSessionDelegate {
    
    /// Handle detected NFC messages
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // This implementation is needed for iOS versions that use this delegate method
        guard let message = messages.first,
              let payload = message.records.first,
              let receivedUserID = String(data: payload.payload, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) else {
            session.invalidate(errorMessage: "Invalid card data")
            return
        }
        
        DispatchQueue.main.async {
            self.receivedCardUserID = receivedUserID
            self.saveReceivedCard(receivedUserID)
        }
        
        session.invalidate()
    }
    
    /// Handle detected NFC messages - newer API (iOS 13+)
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFMessages messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first else {
            session.invalidate(errorMessage: "Invalid card data")
            return
        }
        
        // Try different payload formats to be more flexible
        var receivedUserID: String? = nil
        
        // Try well-known text format first
        if let (text, _) = record.wellKnownTypeTextPayload() {
            receivedUserID = text
        }
        // Fall back to raw payload data
        else if let text = String(data: record.payload, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            receivedUserID = text
        }
        
        if let userID = receivedUserID {
            DispatchQueue.main.async {
                self.receivedCardUserID = userID
                self.saveReceivedCard(userID)
            }
            
            session.alertMessage = "Card received successfully!"
            session.invalidate()
        } else {
            session.invalidate(errorMessage: "Couldn't read business card data")
        }
    }
    
    /// Handle session invalidation with improved error messaging
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isNFCSharing = false
            
            // Provide more user-friendly error messages
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorFirstNDEFTagRead:
                    // This is expected when we read a tag and invalidate the session
                    self.nfcStatus = "Card read complete"
                case .readerSessionInvalidationErrorUserCanceled:
                    self.nfcStatus = "Scanning canceled"
                default:
                    self.nfcStatus = "NFC session error: \(error.localizedDescription)"
                }
            } else {
                self.nfcStatus = "NFC session ended: \(error.localizedDescription)"
            }
            
            print("NFC session invalidated: \(error)")
        }
    }
    
    /// Handle active NFC session
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            self.nfcStatus = "Ready to scan"
            print("NFC session active")
        }
    }
}