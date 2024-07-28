//
//  HomeViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import Foundation

extension CreatorsView {
    class ViewModel: ObservableObject {
        @Published var creators: [Components.Schemas.CreatorModelV3]
        
        init() {
            self.creators = []
        }
        
        func fetchCreators() async {
            do {
                let result = try await CreatorClient.shared.getCreators()
                DispatchQueue.main.async {
                    self.creators = result
                }
            }
            catch {
                print("Error: \(error)")
            }
            
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
