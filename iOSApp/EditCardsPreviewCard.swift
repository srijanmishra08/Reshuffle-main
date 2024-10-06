//
//  EditCardsPreviewCard.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 10/04/24.
//

import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import Firebase
import AuthenticationServices
import GoogleSignIn
import Combine
import MapKit

struct EditableField: View {
    var label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(label)")
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .padding(.top, 5)
                .padding(.leading, 25)

            TextField("", text: $text)
                .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                .background(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 1))
                .padding([.leading, .trailing])
                .padding(.bottom, 5)
        }
    }
}


struct EditCardsPreviewCard: View {
    @Binding var user: BusinessCard

    var body: some View {
        VStack(spacing: 0) {
            CustomCardViewPreview(businessCard: user)
                .previewLayout(.sizeThatFits)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 15) {
                    EditableField(label: "Name", text: $user.name)
                    EditableField(label: "Profession", text: $user.profession)
                    EditableField(label: "Email", text: $user.email)
                    EditableField(label: "Company", text: $user.company)
                    EditableField(label: "Role", text: $user.role)
                    EditableField(label: "Description", text: $user.description)
                    EditableField(label: "Phone Number", text: $user.phoneNumber)
                    EditableField(label: "WhatsApp", text: $user.whatsapp)
                    EditableField(label: "Address", text: $user.address)
                    EditableField(label: "Website", text: $user.website)
                    EditableField(label: "LinkedIn", text: $user.linkedIn)
                    EditableField(label: "Instagram", text: $user.instagram)
                    EditableField(label: "X Handle", text: $user.xHandle)
                }
                .padding(.horizontal)
            }
            .padding(.top, 10)
        }
        .padding(.top, -10)
    }
}


struct EditCardsPreviewCard_Previews: PreviewProvider {
    static var previews: some View {
        let user = BusinessCard(
            id: UUID(),
            name: "John Doe",
            profession: "Software Engineer",
            email: "johndoe@example.com",
            company: "Acme Inc.",
            role: "Developer",
            description: "Passionate about building apps.",
            phoneNumber: "123-456-7890",
            whatsapp: "123-456-7890",
            address: "123 Main St, Anytown, USA",
            website: "www.johndoe.com",
            linkedIn: "linkedin.com/in/johndoe",
            instagram: "@johndoe",
            xHandle: "@johndoe",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
            trackingMode: .follow
        )

        let userBinding = Binding<BusinessCard>(
            get: { user },
            set: { _ in }
        )

        return NavigationView {
            EditCardsPreviewCard(user: userBinding)
                .navigationBarHidden(true)
        }
    }
}
