////
////  NFCSharingView.swift
////  iOSApp
////
////  Created by S on 21/12/24.
////
//
//
//import SwiftUI
//import CoreNFC
//
//struct NFCSharingView: View {
//    @StateObject private var nfcViewModel = NFCBusinessCardSharingViewModel()
//    
//    var body: some View {
//        VStack {
//            Text("NFC Card Sharing")
//                .font(.title)
//                .padding()
//            
//            Text(nfcViewModel.nfcStatus)
//                .foregroundColor(.gray)
//                .padding()
//            
//            Button(action: {
//                nfcViewModel.startNFCSharing()
//            }) {
//                HStack {
//                    Image(systemName: "waves.right")
//                    Text("Share Card via NFC")
//                }
//                .padding()
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//            }
//            .disabled(nfcViewModel.isNFCSharing)
//            
//            if let receivedCardUserID = nfcViewModel.receivedCardUserID {
//                Text("Received Card User ID: \(receivedCardUserID)")
//                    .padding()
//            }
//        }
//    }
//}
//
//struct NFCView_Previews: PreviewProvider {
//    static var previews: some View {
//        NFCSharingView()
//    }
//}
