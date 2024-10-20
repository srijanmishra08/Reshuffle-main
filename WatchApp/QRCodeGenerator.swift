import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    static func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

struct QRCodeView: View {
    let businessCard: BusinessCard?
    
    var body: some View {
        if let card = businessCard {
            Image(uiImage: QRCodeGenerator.generateQRCode(from: card.qrCodeString))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        } else {
            Text("No business card data available")
        }
    }
}

struct BusinessCard: Codable {
    let name: String
    let profession: String
    let email: String
    let phone: String
    
    var qrCodeString: String {
        return "Name: \(name)\nProfession: \(profession)\nEmail: \(email)\nPhone: \(phone)"
    }
    
    var dictionary: [String: String] {
        return [
            "name": name,
            "profession": profession,
            "email": email,
            "phone": phone
        ]
    }
}