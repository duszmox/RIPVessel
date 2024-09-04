//
//  ChannelViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 08. 18..
//

import Foundation

extension ChannelView {
    class ViewModel: ObservableObject {
        @Published var creator: Components.Schemas.CreatorModelV3
        @Published var channelId: String
        init(creator: Components.Schemas.CreatorModelV3, channelId: String) {
            self.creator = creator
            self.channelId = channelId
        }
    }
}
