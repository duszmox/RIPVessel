//
//  Item.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
