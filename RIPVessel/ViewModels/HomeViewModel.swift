//
//  HomeViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import Foundation

extension HomeView {
    class ViewModel: ObservableObject {
        @Published var creators: [Components.Schemas.CreatorModelV3]
        
        init() {
            self.creators = []
        }
        
        func fetchCreators() async {
            do {
                // TODO: Open an issue to have it set to optional
                let result = try await ApiService.shared.client.getCreators(Operations.getCreators.Input(query: Operations.getCreators.Input.Query(search: "")))
                let c = try result.ok.body.json
                DispatchQueue.main.async {
                    self.creators = c
                }
            }
            catch {
                print("Error: \(error)")
            }
            
        }
    }
}
