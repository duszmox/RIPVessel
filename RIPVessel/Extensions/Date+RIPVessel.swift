//
//  Date+RIPVessel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 08. 03..
//

import Foundation

extension Date {
    func timeAgoString() -> String {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate the difference between now and the date
        let components = calendar.dateComponents([.hour], from: self, to: now)
        
        if let hours = components.hour, hours < 24 {
            return "\(hours) hours ago"
        } else {
            // Create a date formatter for the standard date string
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: self)
        }
    }
}
