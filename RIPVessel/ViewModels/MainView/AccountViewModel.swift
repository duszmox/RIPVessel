//
//  AccountViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 04..
//

import Foundation

extension AccountView {
    class ViewModel: ObservableObject {
        @Published var creators: [Components.Schemas.CreatorModelV3]
        
        init() {
            self.creators = []
        }

        func fetchSubscriptions() async {
            
            do {
                let result = try await CreatorClient.shared.getSubscribedCreators()
                DispatchQueue.main.async {
                    self.creators = result
                }
            } catch {
                print("Error: \(error)")
            }
        }

    }
}
