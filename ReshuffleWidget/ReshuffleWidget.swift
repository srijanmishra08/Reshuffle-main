import WidgetKit
import SwiftUI

struct ReShuffleQRWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack {
            Text("My QR Code")
                .font(.headline)
            QRCodeView(qrCodeData: entry.qrCodeData) // Use QRCodeView here
        }
        .padding()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let qrCodeData: String
}

struct ReShuffleQRWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), qrCodeData: "Sample QR Code Data")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), qrCodeData: loadQRCodeData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        let qrCodeData = loadQRCodeData()
        
        let entry = SimpleEntry(date: currentDate, qrCodeData: qrCodeData)
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadQRCodeData() -> String {
        // Fetch the QR code data from UserDefaults
        guard let qrCodeData = UserDefaults.standard.string(forKey: "QRCodeData") else {
            return "No QR Code Available" // Or any default text you prefer
        }
        return qrCodeData
    }
}

// Widget Configuration
@main
struct ReShuffleQRWidget: Widget {
    let kind: String = "ReShuffleQRWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReShuffleQRWidgetProvider()) { entry in
            ReShuffleQRWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ReShuffle QR Widget")
        .description("Display your ReShuffle QR code.")
        .supportedFamilies([.systemSmall])
    }
}

// Preview for the widget
struct ReShuffleQRWidget_Previews: PreviewProvider {
    static var previews: some View {
        ReShuffleQRWidgetEntryView(entry: SimpleEntry(date: Date(), qrCodeData: "Sample QR Code Data"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
