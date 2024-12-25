//import WidgetKit
//import AppIntents
//import SwiftUI
//
//// MARK: - Intent for Displaying QR Code
//struct DisplayQRCodeIntent: WidgetConfigurationIntent {
//    static var title: LocalizedStringResource { "Display QR Code" }
//    static var description: IntentDescription {
//        IntentDescription("Displays your Reshuffle QR code in the widget.")
//    }
//}
//
//
//// MARK: - QR Code Entry
//struct QRCodeEntry: TimelineEntry {
//    let date: Date
//    let qrCodeData: String
//    let qrCodeImage: Image
//}
//
//// MARK: - Reshuffle Widget
//struct ReshuffleWidget: Widget {
//    static let kind: String = "com.srijan.Reshuffle.ReshuffleWidget"
//
//    var body: some WidgetConfiguration {
////        StaticConfiguration(kind: Self.kind, provider: QRCodeProvider()) { entry in
////            QRCodeWidgetView(entry: entry)
////        }
////        .configurationDisplayName("Reshuffle QR Code")
////        .description("Displays your Reshuffle QR code for quick access.")
//        ReShuffleQRWidgetEntryView(entry:   SimpleEntry(date: Date(), qrCodeData: "Sample QR Code Data"))
//        .supportedFamilies([.systemSmall, .systemMedium]) // Supported widget sizes
//    }
//}
//
//// MARK: - Widget View
//struct QRCodeWidgetView: View {
//    var entry: QRCodeEntry
//
//    var body: some View {
//        VStack {
//            entry.qrCodeImage
//                .resizable()
//                .scaledToFit()
//                .frame(width: 125, height: 125) // Set a fixed size for the QR code
//            Text("Scan this QR Code")
//                .font(.caption)
//        }
//        .padding()
//    }
//}
//
//// MARK: - QR Code Configuration Intent
//struct QRCodeConfiguration: ControlConfigurationIntent {
//    static var title: LocalizedStringResource = "QR Code Configuration"
//
//    @Parameter(title: "QR Code ID", default: "default")
//    var qrCodeID: String
//}
//
//// MARK: - Preview Provider for the Widget
//@main
//struct ReshuffleWidgetBundle: WidgetBundle {
//    var body: some Widget {
//        ReshuffleWidget()
//    }
//}

    //////////////////////////////////////////////////////
//// MARK: QR Code Provider for Timeline in Widget
//struct QRCodeProvider: TimelineProvider {
//    func placeholder(in context: Context) -> QRCodeEntry {
//        QRCodeEntry(date: Date(), qrCodeData: "Placeholder QR Code Data", qrCodeImage: Image(systemName: "qrcode"))
//    }
//
////    func getSnapshot(in context: Context, completion: @escaping (QRCodeEntry) -> Void) {
////        let qrCodeData = loadQRCodeData()
////        let entry = QRCodeEntry(date: Date(), qrCodeData: qrCodeData, qrCodeImage: generateQRCode(from: qrCodeData) ?? Image(systemName: "qrcode"))
////        completion(entry)
////    }
////
////    func getTimeline(in context: Context, completion: @escaping (Timeline<QRCodeEntry>) -> Void) {
////        let qrCodeData = loadQRCodeData()
////        let qrCodeImage = generateQRCode(from: qrCodeData) ?? Image(systemName: "qrcode")
////        let entry = QRCodeEntry(date: Date(), qrCodeData: qrCodeData, qrCodeImage: qrCodeImage)
////
////        let timeline = Timeline(entries: [entry], policy: .never)
////        completion(timeline)
////    }
//
//    private func loadQRCodeData() -> String {
//        // Load QR Code data from UserDefaults
//        return UserDefaults.standard.string(forKey: "QRCodeData") ?? "Your QR Code Data"
//    }
//
////    // QR Code generation logic for widget
////    private func generateQRCode(from string: String) -> Image? {
////        guard let data = string.data(using: .utf8) else { return nil }
////
////        let context = CIContext()
////        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
////        filter.setValue(data, forKey: "inputMessage")
////
////        let scale = UIScreen.main.scale
////        let transform = CGAffineTransform(scaleX: scale, y: scale)
////        guard let outputImage = filter.outputImage?.transformed(by: transform) else { return nil }
////
////        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
////            let uiImage = UIImage(cgImage: cgImage)
////            return Image(uiImage: uiImage)
////        } else {
////            return nil
////        }
////    }
//}
