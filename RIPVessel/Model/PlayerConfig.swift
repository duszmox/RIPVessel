//
//  PlayerConfig.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 09..
//
import SwiftUI

struct PlayerConfig: Equatable {
    var position: CGFloat = .zero
    var lastPosition: CGFloat = .zero
    var progress: CGFloat = .zero
    var selectedPlayerItem: Components.Schemas.BlogPostModelV3?
    var showMiniPlayer: Bool = false

    mutating func resetPosition() {
        position = .zero
        lastPosition = .zero
        progress = .zero
    }
}
