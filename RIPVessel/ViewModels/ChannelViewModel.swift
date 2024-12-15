//
//  ChannelViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 08. 18..
//

import Foundation
import SwiftUICore

extension ChannelView {
    class ViewModel: ObservableObject {
        @Published var creator: Components.Schemas.CreatorModelV3?
        @Published var channelId: String
        @Binding var playerConfig: PlayerConfig
        
        init(creatorId: String, channelId: String, playerConfig: Binding<PlayerConfig>) {
            _playerConfig = playerConfig
            self.channelId = channelId
            Task { [weak self] in
                guard let self = self else { return }
                
                do {
                    let fetchedCreator = try await CreatorClient.shared.getCreator(id: creatorId)
                    
                    await MainActor.run {
                        self.creator = fetchedCreator
                    }
                } catch {
                    print(channelId, error)
                }
            }
        }
    }
}
