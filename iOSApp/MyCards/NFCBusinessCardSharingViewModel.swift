////
////  NFCBusinessCardSharingViewModel.swift
////  iOSApp
////
////  Created by S on 21/12/24.
////
//
//
//import Foundation
//import CoreNFC
//import FirebaseFirestore
//import FirebaseAuth
//
//class NFCBusinessCardSharingViewModel: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
//    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
//        <#code#>
//    }
//    
//    
//    
//    // Published properties for UI updates
//    @Published var isNFCSharing = false
//    @Published var nfcStatus: String = ""
//    @Published var receivedCardUserID: String?
//    
//    // NFC session management
//    private var nfcSession: NFCNDEFReaderSession?
//    
//    // Function to check NFC availability
//    func checkNFCAvailability() -> Bool {
//        guard NFCNDEFReaderSession.readingAvailable else {
//            nfcStatus = "NFC is not available on this device"
//            return false
//        }
//        return true
//    }
//    
//    // Start NFC sharing/reading session
//    func startNFCSharing() {
//        guard checkNFCAvailability() else { return }
//        
//        nfcSession = NFCNDEFReaderSession(
//            delegate: self, 
//            queue: nil, 
//            invalidateAfterFirstRead: true
//        )
//        nfcSession?.begin()
//        isNFCSharing = true
//        nfcStatus = "Waiting for NFC interaction..."
//    }
//    
//    // Prepare NFC message with user's card data
//    func prepareNFCMessage() -> NFCNDEFMessage? {
//        guard let currentUser = Auth.auth().currentUser else {
//            nfcStatus = "User not logged in"
//            return nil
//        }
//        
//        // Create NFC payload with user's unique identifier
//        let payload = NFCNDEFPayload(
//            format: .absoluteURI,
//            type: "text/plain".data(using: .utf8)!,
//            identifier: "reshufflecard".data(using: .utf8)!,
//            payload: currentUser.uid.data(using: .utf8)!
//        )
//        
//        return NFCNDEFMessage(records: [payload])
//    }
//    
//    // MARK: - NFCNDEFReaderSessionDelegate Methods
//    
//    // Handle detected NFC messages
//    func readerSession(_ session: NFCNDEFReaderSession, 
//                       didDetectNDEFMessages messages: [NFCNDEFMessage], 
//                       with error: Error?) {
//        guard let message = messages.first,
//              let payload = message.records.first,
//              let receivedUserID = String(data: payload.payload, encoding: .utf8) else {
//            session.invalidate(errorMessage: "Invalid NFC message")
//            return
//        }
//        
//        DispatchQueue.main.async {
//            self.receivedCardUserID = receivedUserID
//            self.saveReceivedCard(receivedUserID)
//        }
//    }
//    
//    // Handle session invalidation
//    func readerSession(_ session: NFCNDEFReaderSession, 
//                       didInvalidateWithError error: Error) {
//        DispatchQueue.main.async {
//            self.nfcStatus = "NFC session error: \(error.localizedDescription)"
//            self.isNFCSharing = false
//        }
//    }
//    
//    // Handle active NFC session
//    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
//        nfcStatus = "NFC session active"
//    }
//    
//    // Save received card to Firestore
//    private func saveReceivedCard(_ receivedUserID: String) {
//        guard let currentUserID = Auth.auth().currentUser?.uid else {
//            nfcStatus = "Current user not authenticated"
//            return
//        }
//        
//        let savedUsersRef = Firestore.firestore().collection("SavedUsers").document(currentUserID)
//        
//        savedUsersRef.getDocument { [weak self] (document, error) in
//            guard let self = self else { return }
//            
//            var scannedUIDs = document?.data()?["scannedUIDs"] as? [String] ?? []
//            
//            if !scannedUIDs.contains(receivedUserID) {
//                scannedUIDs.append(receivedUserID)
//                
//                savedUsersRef.setData(["scannedUIDs": scannedUIDs], merge: true) { error in
//                    if let error = error {
//                        self.nfcStatus = "Error saving received card: \(error.localizedDescription)"
//                    } else {
//                        self.nfcStatus = "Card received and saved successfully"
//                    }
//                }
//            } else {
//                self.nfcStatus = "Card already saved"
//            }
//        }
//    }
//}
