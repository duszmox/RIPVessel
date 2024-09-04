//
//  RecentsView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import SwiftUI

struct RecentsView: View {
    @StateObject private var vm: ViewModel
    @Binding var scrollEnabled: Bool
    
    init(creatorId: String? = nil, channelId: String? = nil, scrollEnabled: Binding<Bool> = .constant(true)) {
        _vm = .init(wrappedValue: .init(creatorId: creatorId, channelId: channelId))
        _scrollEnabled = scrollEnabled
    }
    
    var body: some View {
            ScrollView {
                LazyVStack {
                    if vm.recents.isEmpty {
                        LoadingRecentPostView()
                        LoadingRecentPostView()
                        LoadingRecentPostView()
                    }
                    ForEach(vm.recents, id: \.id) { recent in
                        RecentPostView(post: recent)
                            .onAppear {
                            Task {
                                if recent.id == vm.recents.last?.id {
                                    await vm.fetchRecents()
                                }
                            }
                        }
                    }
                }
            }.onAppear {
                Task {
                    await vm.fetchRecents()
                }
            }.refreshable {
                Task {
                    await vm.fetchRecents(refresh: true)
                }
            }.scrollDisabled(vm.recents.isEmpty && !scrollEnabled)
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation") // Forcing the rotation to portrait
            AppDelegate.orientationLock = .portrait // And making sure it stays that way
        }.onDisappear {
            AppDelegate.orientationLock = .all // Unlocking the rotation when leaving the view
        }
    }
}
