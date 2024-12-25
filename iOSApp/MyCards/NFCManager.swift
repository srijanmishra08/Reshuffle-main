////
////  NFCManager.swift
////  iOSApp
////
////  Created by S on 01/12/24.
////
//
//
//import Foundation
//import CoreNFC
//
//class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
//    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
//        <#code#>
//    }
//    
//    
//    
//    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error, didDetect tags: [NFCNDEFTag]) {
//        
//            guard let tag = tags.first else {
//                session.invalidate(errorMessage: "No NFC tag detected.")
//                return
//            }
//            
//            session.connect(to: tag) { error in
//                if let error = error {
//                    session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
//                    return
//                }
//                
//                tag.queryNDEFStatus { status, capacity, error in
//                    if let error = error {
//                        session.invalidate(errorMessage: "Failed to query tag status: \(error.localizedDescription)")
//                        return
//                    }
//                    
//                    switch status {
//                    case .notSupported:
//                        session.invalidate(errorMessage: "This tag does not support NDEF.")
//                    case .readOnly:
//                        session.invalidate(errorMessage: "This tag is read-only.")
//                    case .readWrite:
//                        guard let nfcMessage = self.nfcMessage else {
//                            session.invalidate(errorMessage: "No message to write.")
//                            return
//                        }
//                        
//                        let payload = NFCNDEFPayload(
//                            format: .nfcWellKnown,
//                            type: "T".data(using: .utf8)!,
//                            identifier: Data(),
//                            payload: nfcMessage.data(using: .utf8)!
//                        )
//                        let message = NFCNDEFMessage(records: [payload])
//                        
//                        tag.writeNDEF(message) { error in
//                            if let error = error {
//                                session.invalidate(errorMessage: "Failed to write to tag: \(error.localizedDescription)")
//                            } else {
//                                session.alertMessage = "Message written successfully!"
//                                session.invalidate()
//                            }
//                        }
//                    @unknown default:
//                        session.invalidate(errorMessage: "Unknown tag status.")
//                    }
//                }
//            }
//        
//    }
//    
//    @Published var isScanning = false
//    @Published var nfcMessage: String?
//    var nfcSession: NFCNDEFReaderSession?
//    var onNFCDetected: ((String) -> Void)?
//    
//    func startScanning(onDetected: @escaping (String) -> Void) {
//        guard NFCNDEFReaderSession.readingAvailable else {
//            print("NFC not available on this device")
//            return
//        }
//        
//        self.onNFCDetected = onDetected
//        nfcSession = NFCNDEFReaderSession(delegate: self,
//                                          queue: DispatchQueue.main,
//                                          invalidateAfterFirstRead: true)
//        nfcSession?.alertMessage = "Hold your device near another iPhone to share your card"
//        nfcSession?.begin()
//    }
//    
//    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
//        guard let message = messages.first,
//              let record = message.records.first,
//              let payload = String(data: record.payload, encoding: .utf8) else {
//            return
//        }
//        
//        DispatchQueue.main.async {
//            self.onNFCDetected?(payload)
//        }
//    }
//    
//    func writeNFCMessage(userID: String) {
//        guard NFCNDEFReaderSession.readingAvailable else {
//            print("NFC not available on this device")
//            return
//        }
//        
//        nfcSession = NFCNDEFReaderSession(delegate: self,
//                                          queue: DispatchQueue.main,
//                                          invalidateAfterFirstRead: false)
//        nfcSession?.alertMessage = "Hold your device near another NFC tag to write your data"
//        nfcSession?.begin()
//        
//        let payload = NFCNDEFPayload(
//            format: .nfcWellKnown,
//            type: "T".data(using: .utf8)!,
//            identifier: Data(),
//            payload: userID.data(using: .utf8)!
//        )
//        let message = NFCNDEFMessage(records: [payload])
//        
//        self.nfcMessage = userID
//    }
//    
//    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
//        guard let tag = tags.first else {
//            session.invalidate(errorMessage: "No NFC tag detected.")
//            return
//        }
//        
//        session.connect(to: tag) { error in
//            if let error = error {
//                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
//                return
//            }
//            
//            tag.queryNDEFStatus { status, capacity, error in
//                if let error = error {
//                    session.invalidate(errorMessage: "Failed to query tag status: \(error.localizedDescription)")
//                    return
//                }
//                
//                switch status {
//                case .notSupported:
//                    session.invalidate(errorMessage: "This tag does not support NDEF.")
//                case .readOnly:
//                    session.invalidate(errorMessage: "This tag is read-only.")
//                case .readWrite:
//                    guard let nfcMessage = self.nfcMessage else {
//                        session.invalidate(errorMessage: "No message to write.")
//                        return
//                    }
//                    
//                    let payload = NFCNDEFPayload(
//                        format: .nfcWellKnown,
//                        type: "T".data(using: .utf8)!,
//                        identifier: Data(),
//                        payload: nfcMessage.data(using: .utf8)!
//                    )
//                    let message = NFCNDEFMessage(records: [payload])
//                    
//                    tag.writeNDEF(message) { error in
//                        if let error = error {
//                            session.invalidate(errorMessage: "Failed to write to tag: \(error.localizedDescription)")
//                        } else {
//                            session.alertMessage = "Message written successfully!"
//                            session.invalidate()
//                        }
//                    }
//                @unknown default:
//                    session.invalidate(errorMessage: "Unknown tag status.")
//                }
//            }
//        }
//    }
//}
