import SwiftUI
import MapKit

enum CardTemplate: String, CaseIterable {
    case template1 = "Template 1"
    case template2 = "Template 2"
    case template3 = "Template 3"
    
    @ViewBuilder
    func view(for businessCard: BusinessCard, cardColor: UIColor) -> some View {
        switch self {
        case .template1:
            Template1View(businessCard: businessCard, cardColor: cardColor)
        case .template2:
            Template2View(businessCard: businessCard, cardColor: cardColor)
        case .template3:
            Template3View(businessCard: businessCard, cardColor: cardColor)
        }
    }
}

// Example data for preview
extension BusinessCard {
    static var previewExample: BusinessCard {
        BusinessCard(
            id: UUID(),
            name: "John Doe",
            profession: "Technology",
            email: "john.doe@example.com",
            company: "Tech Corp",
            role: "Software Engineer",
            description: "Experienced software developer",
            phoneNumber: "+1 (555) 123-4567",
            whatsapp: "+1 (555) 123-4567",
            address: "123 Tech Street, Silicon Valley",
            website: "www.example.com",
            linkedIn: "johndoe",
            instagram: "johndoe",
            xHandle: "@johndoe",
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ),
            trackingMode: .follow,
            cardColor: UIColor.systemBlue
        )
    }
}

struct CardTextView: View {
    let text: String
    let font: Font
    let alignment: TextAlignment = .leading
    
    var body: some View {
        Text(text)
            .font(font)
            .multilineTextAlignment(alignment)
    }
}

struct Template1View: View {
    let businessCard: BusinessCard
    let cardColor: UIColor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardTextView(text: businessCard.name, font: .title.bold())
            CardTextView(text: businessCard.role, font: .subheadline)
            CardTextView(text: businessCard.company, font: .subheadline)
            
            if !businessCard.description.isEmpty {
                CardTextView(text: businessCard.description, font: .caption)
                    .padding(.vertical, 4)
            }
            
            Divider()
            
            Group {
                CardTextView(text: businessCard.email, font: .caption)
                CardTextView(text: businessCard.phoneNumber, font: .caption)
                if !businessCard.website.isEmpty {
                    CardTextView(text: businessCard.website, font: .caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(cardColor))
        .cornerRadius(10)
    }
}

struct Template2View: View {
    let businessCard: BusinessCard
    let cardColor: UIColor
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                CardTextView(text: businessCard.name, font: .title2.bold())
                CardTextView(text: businessCard.role, font: .subheadline)
                CardTextView(text: businessCard.company, font: .subheadline)
                if !businessCard.description.isEmpty {
                    CardTextView(text: businessCard.description, font: .caption)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Group {
                    CardTextView(text: businessCard.email, font: .caption)
                    CardTextView(text: businessCard.phoneNumber, font: .caption)
                    if !businessCard.whatsapp.isEmpty {
                        CardTextView(text: "WhatsApp: \(businessCard.whatsapp)", font: .caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(cardColor))
        .cornerRadius(10)
    }
}

struct Template3View: View {
    let businessCard: BusinessCard
    let cardColor: UIColor
    
    var body: some View {
        VStack(spacing: 12) {
            CardTextView(text: businessCard.name, font: .title.bold())
                .padding(.bottom, 4)
            
            Group {
                CardTextView(text: businessCard.role, font: .subheadline)
                CardTextView(text: businessCard.company, font: .subheadline)
                if !businessCard.description.isEmpty {
                    CardTextView(text: businessCard.description, font: .caption)
                }
            }
            .padding(.vertical, 2)
            
            Divider()
                .padding(.vertical, 4)
            
            Group {
                CardTextView(text: businessCard.email, font: .caption)
                CardTextView(text: businessCard.phoneNumber, font: .caption)
                if !businessCard.address.isEmpty {
                    CardTextView(text: businessCard.address, font: .caption)
                }
            }
            
            if !businessCard.linkedIn.isEmpty || !businessCard.instagram.isEmpty || !businessCard.xHandle.isEmpty {
                HStack(spacing: 12) {
                    if !businessCard.linkedIn.isEmpty {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                    }
                    if !businessCard.instagram.isEmpty {
                        Image(systemName: "camera")
                            .foregroundColor(.purple)
                    }
                    if !businessCard.xHandle.isEmpty {
                        Image(systemName: "message")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(cardColor))
        .cornerRadius(10)
    }
}

#if DEBUG
struct CardTemplatePreview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(CardTemplate.allCases, id: \.self) { template in
                template.view(
                    for: BusinessCard.previewExample,
                    cardColor: UIColor.systemBlue
                )
            }
        }
        .padding()
    }
}
#endif
