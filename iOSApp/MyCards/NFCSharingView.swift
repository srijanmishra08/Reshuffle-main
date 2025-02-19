//
//  NFCSharingView.swift
//  iOSApp
//
//  Created by S on 21/12/24.
//


import SwiftUI
import CoreNFC
struct NFCSharingView: View {
    @StateObject private var nfcViewModel = NFCBusinessCardSharingViewModel()
    @EnvironmentObject var userDataViewModel: UserDataViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("NFC Card Sharing")
                .font(.title)
                .padding()
            
            if let businessCard = userDataViewModel.businessCard {
                Text("Sharing \(businessCard.name)'s Card")
                    .font(.headline)
                    .padding()
            }
            
            Text(nfcViewModel.nfcStatus)
                .foregroundColor(.gray)
                .padding()
            
            Button(action: {
                nfcViewModel.shareBusinessCard()
            }) {
                HStack {
                    Image(systemName: "waves.right")
                    Text("Share Card via NFC")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(nfcViewModel.isNFCSharing)
            
            if let receivedCardUserID = nfcViewModel.receivedCardUserID {
                Text("Card received!")
                    .foregroundColor(.green)
                    .padding()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
        }
        .onReceive(nfcViewModel.$receivedCardUserID) { receivedID in
            if receivedID != nil {
                // Wait a moment before dismissing
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct NFCView_Previews: PreviewProvider {
    static var previews: some View {
        NFCSharingView()
    }
}
