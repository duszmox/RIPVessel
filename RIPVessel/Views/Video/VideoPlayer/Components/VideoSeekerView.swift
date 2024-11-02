//
//  VideoSeekerView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 11. 02..
//

import Foundation
import SwiftUI

struct VideoSeekerView: View {
    @Binding var progress: CGFloat
    @GestureState var isDragging: Bool
    @Binding var isSeeking: Bool
    @Binding var lastDraggedValue: CGFloat
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var showPlayerControls: Bool

    var isRotated: Bool
    var size: CGSize
    var seekAction: (CGFloat) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray)
                .frame(width: isRotated ? size.height : size.width)

            Rectangle()
                .fill(Color.cyan)
                .frame(width: max((progress.isNaN ? 0 : progress) * (isRotated ? size.height : size.width), 0))
        }
        .frame(height: 3)
        .overlay(alignment: .leading) {
            Circle()
                .fill(Color.cyan)
                .frame(width: 15, height: 15)
                .scaleEffect(showPlayerControls || isDragging ? 1 : 0.001, anchor: .center)
                .frame(width: 50, height: 50)
                .contentShape(Rectangle())
                .offset(x: progress * ((isRotated ? size.height : size.width) - 15))
                .gesture(
                    DragGesture()
                        .updating($isDragging) { _, out, _ in
                            out = true
                        }
                        .onChanged { value in
                            let transitionX = value.translation.width
                            let newProgress = (transitionX / ((isRotated ? size.height : size.width) - 15)) + lastDraggedValue
                            progress = max(min(newProgress, 1), 0)
                            if let totalDuration = duration as Double? {
                                currentTime = progress * totalDuration
                            }
                            isSeeking = true
                        }
                        .onEnded { _ in
                            lastDraggedValue = progress
                            seekAction(progress)
                        }
                )
                .frame(width: 15, height: 15)
        }
        .padding(EdgeInsets(
            top: 0,
            leading: isRotated ? 40 : 0,
            bottom: isRotated ? 10 : 0,
            trailing: isRotated ? 40 : 0
        ))
        .opacity(showPlayerControls ? 1 : isRotated ? 0 : 1)
    }
}
