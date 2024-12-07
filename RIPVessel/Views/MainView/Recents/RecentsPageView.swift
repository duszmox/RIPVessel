//
//  RecentsPageView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 07..
//

import SwiftUI

struct RecentsPageView: View {
    @State private var scrollEnabled: Bool = false
    @State private var shouldRefresh: Bool = false

    var body: some View {
        ScrollView {
            RecentsView(scrollEnabled: $scrollEnabled, shouldRefresh: $shouldRefresh)
        }.refreshable {
            shouldRefresh = true
        }
        .scrollDisabled(!scrollEnabled)
        .onAppear {
           AppDelegate.rotateScreen(to: .portrait)
           AppDelegate.orientationLock = .portrait
        }.onDisappear {
           AppDelegate.orientationLock = .allButUpsideDown
           AppDelegate.rotateScreen(to: .portrait)
        }.navigationTitle("Recent Posts")

    }
}
