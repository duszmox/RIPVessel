//
//  VideoViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import Foundation

extension VideoView {
    class ViewModel: ObservableObject {
        @Published var post: Components.Schemas.BlogPostModelV3
        @Published var stream: Components.Schemas.CdnDeliveryV3Response?
        @Published var qualities: [Components.Schemas.CdnDeliveryV3Variant] = []
        @Published var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
        
        init(post: Components.Schemas.BlogPostModelV3) {
            self.post = post
            Task {
                do {
                    let response = try await ApiService.shared.client.getDeliveryInfoV3(query: Operations.getDeliveryInfoV3.Input.Query(scenario: .onDemand, entityId: post.videoAttachments!.first!))
                    let stream = try response.ok.body.json
                    if let variants = stream.groups.first?.variants {
                        DispatchQueue.main.async {
                            self.qualities = variants
                            self.currentQuality = variants.first(where: { $0.label == "1080p" }) ?? variants.first!
                        }
                    }
                    DispatchQueue.main.async {
                        self.stream = stream
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }
        
        func setQuality(to variant: Components.Schemas.CdnDeliveryV3Variant) {
            currentQuality = variant
        }
    }

}
