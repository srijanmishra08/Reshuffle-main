
// ReshuffleWidget.swift (Static Widget)
import WidgetKit
import SwiftUI
// SharedUserDefaults.swift
import Foundation
import WidgetKit

struct SharedUserDefaults {
    static let appGroupIdentifier = "group.com.reshuffle.widget" // Your app group identifier
    static let qrCodeKey = "QRCodeData"
    
    static var shared: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    static func saveQRCode(_ data: String) {
        shared?.set(data, forKey: qrCodeKey)
        shared?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func loadQRCode() -> String {
        shared?.string(forKey: qrCodeKey) ?? "No QR Code Available"
    }
}


struct SimpleEntry: TimelineEntry {
    let date: Date
    let qrCodeData: String
}

struct ReShuffleQRWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), qrCodeData: "")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let qrCodeData = loadQRCodeData()
        let entry = SimpleEntry(date: Date(), qrCodeData: qrCodeData)
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
        // Try to get UID from shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.reshuffle.widget"),
           let uid = sharedDefaults.string(forKey: "QRCodeData") {
            return uid
        }
        return ""
    }
}

struct ReShuffleQRWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)

            // QR Code centered
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                    QRCodeView(qrCodeData: entry.qrCodeData)
                        .padding(16)
                }
                .frame(width: 160, height: 160)
            }
        }
    }
}



// Preview provider
struct ReShuffleQRWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReShuffleQRWidgetEntryView(entry: SimpleEntry(date: Date(), qrCodeData: "SampleQRData"))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
    }
}
@main
struct ReShuffleQRWidget: Widget {
    let kind: String = "ReShuffleQRWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReShuffleQRWidgetProvider()) { entry in
            ReShuffleQRWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Add this
        }
        .configurationDisplayName("ReShuffle QR Widget")
        .description("Display your ReShuffle QR code.")
        .supportedFamilies([.systemSmall, .systemMedium]) // Update supported sizes
    }
}
