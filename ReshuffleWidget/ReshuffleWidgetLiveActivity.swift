//
//  ReshuffleWidgetLiveActivity.swift
//  ReshuffleWidget
//
//  Created by S on 20/10/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ReshuffleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var qrCodeData: String
    }

    var name: String
}

struct ReshuffleWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReshuffleWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Reshuffle QR Code")
                    .font(.headline)
                QRCodeView(qrCodeData: context.state.qrCodeData)
                    .frame(width: 200, height: 200)
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.
                DynamicIslandExpandedRegion(.leading) {
                    Text("Reshuffle")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.name)
                }
                DynamicIslandExpandedRegion(.center) {
                    QRCodeView(qrCodeData: context.state.qrCodeData)
                        .frame(width: 100, height: 100)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Scan to connect")
                }
            } compactLeading: {
                Image(systemName: "qrcode")
            } compactTrailing: {
                Text("Scan")
            } minimal: {
                Image(systemName: "qrcode")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ReshuffleWidgetAttributes {
    fileprivate static var preview: ReshuffleWidgetAttributes {
        ReshuffleWidgetAttributes(name: "John's QR")
    }
}

extension ReshuffleWidgetAttributes.ContentState {
    fileprivate static var sampleQR: ReshuffleWidgetAttributes.ContentState {
        ReshuffleWidgetAttributes.ContentState(qrCodeData: "Sample QR Code Data")
    }
}

#Preview("Notification", as: .content, using: ReshuffleWidgetAttributes.preview) {
   ReshuffleWidgetLiveActivity()
} contentStates: {
    ReshuffleWidgetAttributes.ContentState.sampleQR
}
