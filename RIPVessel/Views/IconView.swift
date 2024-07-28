//
//  IconView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import SwiftUI

struct IconView: View {
    @StateObject private var iconService = IconService.shared
    let url: String
    var size: CGSize? = nil
    
    var body: some View {
        if let iconURL = URL(string: url),
           let image = iconService.pendingImages[iconURL.absoluteString] {
            Image(uiImage: image)
                .resizable().scaledToFit()
                .frame(width: size?.width, height: size?.height)
        } else {
            Color.gray
                .onAppear {
                    iconService.fetchIcon(url: url)
                }
        }
    }
}
