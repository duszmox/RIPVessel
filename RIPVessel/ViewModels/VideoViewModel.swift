//
//  VideoViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import Foundation

extension VideoView {
    class ViewModel: ObservableObject {
        @Published var post: Components.Schemas.ContentPostV3Response?
        @Published var stream: Components.Schemas.CdnDeliveryV3Response?
        @Published var qualities: [Components.Schemas.CdnDeliveryV3Variant] = []
        @Published var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
        @Published var video: Components.Schemas.ContentVideoV3Response?
        @Published var description: String
        
        init(post: Components.Schemas.BlogPostModelV3) {
            description = post.text
            Task {
                await initialize(post: post)
            }
        }
        
        @MainActor
        private func initialize(post: Components.Schemas.BlogPostModelV3) async {
            do {
                let fetchedPost = try await fetchPostContent(by: post.id)
                self.post = fetchedPost
                await fetchVideoContent()
                await fetchDeliveryInfo()
            } catch {
                print("Error initializing ViewModel: \(error)")
            }
        }
        
        private func fetchPostContent(by id: String) async throws -> Components.Schemas.ContentPostV3Response {
            let postContentResponse = try await ApiService.shared.client.getBlogPost(
                .init(query: Operations.getBlogPost.Input.Query(id: id))
            )
            let post = try postContentResponse.ok.body.json
            return post
        }
        
        private func fetchVideoContent() async {
            guard let video = post?.videoAttachments?.first else {
                print("No video attachments available")
                return
            }
            
            do {
                let videoContentResponse = try await ApiService.shared.client.getVideoContent(
                    .init(query: Operations.getVideoContent.Input.Query(id: video.id))
                )
                let fetchedVideo = try videoContentResponse.ok.body.json
                await MainActor.run {
                    self.video = fetchedVideo
                }
            } catch {
                print("Error fetching video content: \(error)")
            }
        }
        
        private func fetchDeliveryInfo() async {
            guard let video = post?.videoAttachments?.first else {
                print("No video attachments available")
                return
            }
            
            do {
                let response = try await ApiService.shared.client.getDeliveryInfoV3(
                    query: Operations.getDeliveryInfoV3.Input.Query(scenario: .onDemand, entityId: video.id)
                )
                let fetchedStream = try response.ok.body.json
                if let variants = fetchedStream.groups.first?.variants {
                    await MainActor.run {
                        self.qualities = variants
                        self.currentQuality = variants.first(where: { $0.label == "1080p" }) ?? variants.first!
                    }
                }
                await MainActor.run {
                    self.stream = fetchedStream
                }
            } catch {
                print("Error fetching delivery info: \(error)")
            }
        }
        
        func setQuality(to variant: Components.Schemas.CdnDeliveryV3Variant) {
            Task { @MainActor in
                self.currentQuality = variant
            }
        }
        
        func like() {
            Task.detached {
                await self.updateUserInteraction(action: .like)
            }
        }
        
        func dislike() {
            Task.detached {
                await self.updateUserInteraction(action: .dislike)
            }
        }
        
        private func updateUserInteraction(action: Components.Schemas.UserInteractionModelPayload) async {
            do {
                let request = Components.Schemas.ContentLikeV3Request(
                    contentType: .blogPost,
                    id: post?.id ?? ""
                )
                let interaction: Components.Schemas.UserInteractionModel
                switch action {
                case .like:
                    let response = try await ApiService.shared.client.likeContent(body: .json(request))
                    interaction = try response.ok.body.json
                case .dislike:
                    let response = try await ApiService.shared.client.dislikeContent(body: .json(request))
                    interaction = try response.ok.body.json
                }
                
                await MainActor.run {
                    if let hasLiked = self.video?.userInteraction?.contains(.like), hasLiked {
                        if !interaction.contains(.like) {
                            self.post?.likes -= 1
                        }
                    } else if interaction.contains(.like) {
                        self.post?.likes += 1
                    }
                    
                    if let hasDisliked = self.video?.userInteraction?.contains(.dislike), hasDisliked {
                        if !interaction.contains(.dislike) {
                            self.post?.dislikes -= 1
                        }
                    } else if interaction.contains(.dislike) {
                        self.post?.dislikes += 1
                    }
                    
                    self.post?.userInteraction = interaction
                }
            } catch {
                print("Error updating user interaction: \(error)")
            }
        }
    }
}
