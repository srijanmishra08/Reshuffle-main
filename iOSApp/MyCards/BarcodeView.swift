import SwiftUI
import CoreImage
import UIKit
import FirebaseAuth

struct QRCodeView: View {
    let qrCodeData: String
    
    public func generateQRCode() -> Image? {
        guard let data = qrCodeData.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 9, y: 9)
        guard let outputImage = filter.outputImage?.transformed(by: transform),
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
    
    var body: some View {
        Group {
            if let qrCodeImage = generateQRCode() {
                qrCodeImage
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 125, height: 125) // Set the frame size here
            } else {
                Text("Unable to generate QR code")
                    .frame(width: 125, height: 125) // Set the frame size here
            }
        }
    }
}
