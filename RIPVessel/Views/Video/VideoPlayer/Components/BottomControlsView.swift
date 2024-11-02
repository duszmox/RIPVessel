//
//  BottomControlsView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 11. 02..
//

import Foundation
import SwiftUI

struct BottomControlsView: View {
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var isRotated: Bool
    @Binding var showPlayerControls: Bool
    @Binding var isSeeking: Bool

    var size: CGSize
    var safeArea: EdgeInsets
    var toggleRotation: () -> Void

    var body: some View {
        HStack {
            Text("\(currentTime.asString(style: .positional))/\(duration.asString(style: .positional))")
                .foregroundColor(.white)
                .font(.system(size: 12))
                .fontWeight(.semibold)
                .padding(.horizontal, 10)

            Spacer()

            Button(action: toggleRotation) {
                Image(systemName: isRotated ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 8)
            .frame(width: 50, height: 50)
            .contentShape(Rectangle())
        }
        .opacity(showPlayerControls ? 1 : isSeeking ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: showPlayerControls)
        .padding(EdgeInsets(
            top: 0,
            leading: isRotated ? 40 : 0,
            bottom: isRotated ? 10 : 0,
            trailing: isRotated ? 40 : 0
        ))
    }
}
