//
//  TopControlsView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 11. 02..
//

import Foundation
import SwiftUI

struct TopControlsView: View {
    var title: String
    @Binding var showPlayerControls: Bool
    var isRotated: Bool
    var safeArea: EdgeInsets

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.leading, safeArea.bottom)
        .padding(.trailing, safeArea.top)
        .opacity(showPlayerControls ? (isRotated ? 1 : 0) : 0)
    }
}
