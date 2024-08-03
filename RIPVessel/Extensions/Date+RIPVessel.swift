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
        
        let components = calendar.dateComponents([.hour, .minute], from: self, to: now)
        
        if let hours = components.hour, hours < 24 {
            if hours == 0, let minutes = components.minute, minutes > 0 {
                return "\(minutes) minutes ago"
            } else {
                return "\(hours) hours ago"
            }
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: self)
        }
    }
}
