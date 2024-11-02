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
    
    @State var isSpecificChannel: Bool
    
    init(creatorId: String? = nil, channelId: String? = nil, scrollEnabled: Binding<Bool> = .constant(true)) {
        _vm = .init(wrappedValue: .init(creatorId: creatorId, channelId: channelId))
        _scrollEnabled = scrollEnabled
        _isSpecificChannel = .init(initialValue: creatorId != nil || channelId != nil)
    }
    
    var body: some View {
            ScrollView {
                LazyVGrid(columns: [.init()]) {
                    if vm.recents.isEmpty {
                        LoadingRecentPostView()
                        LoadingRecentPostView()
                        LoadingRecentPostView()
                    }
                    ForEach(vm.recents, id: \.id) { recent in
                        RecentPostView(post: recent, isSpecificChannel: isSpecificChannel)
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
            AppDelegate.orientationLock = .portrait 
        }.onDisappear {
            AppDelegate.orientationLock = .allButUpsideDown
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
}
