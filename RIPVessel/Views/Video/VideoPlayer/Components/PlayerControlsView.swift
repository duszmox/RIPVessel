//
//  PlayerControlsView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 11. 02..
//

import Foundation
import SwiftUI

struct PlayerControlsView: View {
    @Binding var isPlaying: Bool
    @Binding var isFinishedPlaying: Bool
    @Binding var isBuffering: Bool
    @Binding var showPlayerControls: Bool
    var isDragging: Bool

    var seekBackward: () -> Void
    var seekForward: () -> Void
    var playPauseAction: () -> Void

    var body: some View {
        HStack(spacing: 25) {
            Button(action: seekBackward) {
                Image(systemName: "gobackward.10")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle().fill(Color.black.opacity(0.35))
                    }
            }
            Button(action: playPauseAction) {
                VStack {
                    if isBuffering {
                        ProgressView()
                    } else {
                        Image(systemName: isFinishedPlaying ? "arrow.clockwise" : (isPlaying ? "pause.fill" : "play.fill"))
                    }
                }
                .font(.title)
                .foregroundColor(.white)
                .padding(15)
                .background {
                    Circle().fill(Color.black.opacity(0.35))
                }
                .scaleEffect(1.1)
            }
            Button(action: seekForward) {
                Image(systemName: "goforward.10")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle().fill(Color.black.opacity(0.35))
                    }
            }
        }
        .opacity(showPlayerControls && !isDragging ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDragging)
    }
}
