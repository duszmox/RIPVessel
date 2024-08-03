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
        
        init(post: Components.Schemas.BlogPostModelV3) {
            self.post = post
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
