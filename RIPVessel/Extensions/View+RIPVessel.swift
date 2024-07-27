//
//  View+RIPVessel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUICore

extension View {
    func roundedBorder(cornerRadius: CGFloat, borderColor: Color, lineWidth: CGFloat) -> some View {
            self
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: lineWidth)
                )
        }
}
