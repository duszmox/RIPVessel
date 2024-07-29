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
    }
}
