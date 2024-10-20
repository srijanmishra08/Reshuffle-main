import SwiftUI
import CoreImage
import UIKit

struct QRCodeView: View {
    let qrCodeData: String

    // Function to save QR Code data to UserDefaults
    private func saveQRCodeData() {
        UserDefaults.standard.set(qrCodeData, forKey: "QRCodeData")
    }

    public func generateQRCode() -> Image? {
        // Save QR Code data to UserDefaults before generating the QR code
        saveQRCodeData()
        
        guard let data = qrCodeData.data(using: .utf8) else { return nil }

        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")

        let scale = UIScreen.main.scale
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        guard let outputImage = filter.outputImage?.transformed(by: transform) else { return nil }

        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }

    var body: some View {
        Group {
            if let qrCodeImage = generateQRCode() {
                qrCodeImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 125, height: 125)
            } else {
                Text("Unable to generate QR code")
            }
        }
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(qrCodeData: "Sample QR Code Data")
    }
}
