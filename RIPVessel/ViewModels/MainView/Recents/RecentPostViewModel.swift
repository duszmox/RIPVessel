//
//  RecentPostViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import Foundation

extension RecentPostView {
    class ViewModel: ObservableObject {
        @Published var post: Components.Schemas.BlogPostModelV3
        @Published var isSpecificChannel: Bool
        
        init(post: Components.Schemas.BlogPostModelV3, isSpecificChannel: Bool) {
            self.post = post
            self.isSpecificChannel = isSpecificChannel
        }
        
        func getChannelModel(from payload: Components.Schemas.BlogPostModelV3.channelPayload) -> Components.Schemas.ChannelModel? {
            switch payload {
            case .ChannelModel(let channelModel):
                return channelModel
            case .case2:
                return nil
            }
        }
    }
}
