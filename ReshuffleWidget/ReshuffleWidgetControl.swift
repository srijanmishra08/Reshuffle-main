////
////  ReshuffleWidgetControl.swift
////  ReshuffleWidget
////
////  Created by S on 20/10/24.
////
//
//import AppIntents
//import SwiftUI
//import WidgetKit
//
//struct ReshuffleWidgetControl: ControlWidget {
//    static let kind: String = "com.srijan.Reshuffle.ReshuffleWidget"
//
//    var body: some ControlWidgetConfiguration {
//        AppIntentControlConfiguration(
//            kind: Self.kind,
//            provider: Provider()
//        ) { value in
//            QRCodeControlTemplate(value: value)
//        }
//        .displayName("Reshuffle QR Code")
//        .description("Display your Reshuffle QR code for quick access.")
//    }
//}
//
//extension ReshuffleWidgetControl {
//    struct Value {
//        var qrCodeData: String
//    }
//

import WidgetKit
import AppIntents

//// Custom ControlWidgetTemplate for QR Code Display
//struct QRCodeControlTemplate: ControlWidgetTemplate {
//    let value: ReshuffleWidgetControl.Value
//
//    // This is the required view for ControlWidgetTemplate
//    var body: some View {
//        QRCodeView(qrCodeData: value.qrCodeData)
//            .frame(width: 125, height: 125)
//    }
//}
//
//// QRCodeView used to generate the QR code from provided data
//struct QRCodeView: View {
//    let qrCodeData: String
//
//    private func generateQRCode() -> Image? {
//        guard let data = qrCodeData.data(using: .utf8) else { return nil }
//
//        let context = CIContext()
//        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
//        filter.setValue(data, forKey: "inputMessage")
//
//        let scale = UIScreen.main.scale
//        let transform = CGAffineTransform(scaleX: scale, y: scale)
//        guard let outputImage = filter.outputImage?.transformed(by: transform) else { return nil }
//
//        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
//            let uiImage = UIImage(cgImage: cgImage)
//            return Image(uiImage: uiImage)
//        } else {
//            return nil
//        }
//    }
//
//    var body: some View {
//        Group {
//            if let qrCodeImage = generateQRCode() {
//                qrCodeImage
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 125, height: 125)
//            } else {
//                Text("Unable to generate QR code")
//            }
//        }
//    }
//}
