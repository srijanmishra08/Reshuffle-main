//
//  Extensions.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//

import Foundation


extension Int {
    var timeStringConverter : String{
        
        let timestampDate = NSDate(timeIntervalSince1970: TimeInterval(self))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        let time = dateFormatter.string(from: timestampDate as Date)
        
        return time
    }
}
