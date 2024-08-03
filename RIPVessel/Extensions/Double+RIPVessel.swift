//
//  Double+RIPVessel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 08. 03..
//

import Foundation

extension Double {
    func asString(style: DateComponentsFormatter.UnitsStyle, behavior: DateComponentsFormatter.ZeroFormattingBehavior = .default) -> String {
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        if self >= 3600 {
            let hours = Int(self) / 3600
            return String(format:"%01d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format:"%01d:%02d", minutes, seconds)
    }
}
