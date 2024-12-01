//
//  PlayerViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 04..
//

import AVFoundation
import Combine

class PlayerViewModel: ObservableObject {
    @Published var player: AVPlayer
    
    init(url: URL) {
        let asset = AVURLAsset(
            url: url,
            options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: true,
                AVURLAssetHTTPCookiesKey: HTTPCookieStorage.shared.cookies as Any
            ]
        )
        let item = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: item)
        self.player.usesExternalPlaybackWhileExternalScreenIsActive = true
    }
    
    func updatePlayerItem(url: URL) {
        let asset = AVURLAsset(
            url: url,
            options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: true,
                AVURLAssetHTTPCookiesKey: HTTPCookieStorage.shared.cookies as Any
            ]
        )
        let item = AVPlayerItem(asset: asset)
        self.player.replaceCurrentItem(with: item)
    }
}
