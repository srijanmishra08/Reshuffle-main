// ReshuffleWidgetAttributes.swift
import ActivityKit
import WidgetKit
import SwiftUI

struct ReshuffleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var qrCodeData: String
    }
    
    var name: String
}
