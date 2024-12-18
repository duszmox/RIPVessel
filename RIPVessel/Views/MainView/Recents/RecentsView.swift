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
    @Binding var shouldRefresh: Bool

    @State var isSpecificChannel: Bool

    init(creatorId: String? = nil, channelId: String? = nil, scrollEnabled: Binding<Bool> = .constant(true), shouldRefresh: Binding<Bool> = .constant(false)) {
        _vm = .init(wrappedValue: .init(creatorId: creatorId, channelId: channelId))
        _scrollEnabled = scrollEnabled
        _isSpecificChannel = .init(initialValue: creatorId != nil || channelId != nil)
        _shouldRefresh = shouldRefresh
    }

    var body: some View {
        LazyVGrid(columns: [.init()]) {
            if vm.recents.isEmpty {
                LoadingRecentPostView()
                LoadingRecentPostView()
                LoadingRecentPostView()
            }
            ForEach(vm.recents, id: \.id) { recent in
                RecentPostView(post: recent, isSpecificChannel: isSpecificChannel, progress: vm.progresses[recent.id], updateProgress: vm.updateProgress)
                        .onAppear {
                            Task {
                                if recent.id == vm.recents.last?.id {
                                    await vm.fetchRecents()
                                }
                            }
                }
               
            }.onAppear {
                scrollEnabled = true
            }
        }
        .onAppear {
            Task {
                await vm.fetchRecents()
            }
        }.onChange(of: shouldRefresh, perform: { newVal in
            Task {
                await vm.fetchRecents(refresh: true)
            }
            shouldRefresh = false
        })
        .scrollDisabled(vm.recents.isEmpty && !scrollEnabled)
    }
}
