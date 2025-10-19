//
//  Tab.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 09..
//

import SwiftUI

/// Tab's
enum Tab: String, CaseIterable {
    case recents = "Recents"
    case creators = "Creators"
    case you = "You"

    var symbol: String {
        switch self {
        case .recents:
            "house.fill"
        case .creators:
            "books.vertical.fill"
        case .you:
            "person.circle.fill"
        }
    }
}
