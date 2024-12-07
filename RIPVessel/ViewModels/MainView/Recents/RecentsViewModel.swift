//
//  RecentsViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import Foundation
typealias Creator = Components.Schemas.CreatorModelV3
extension RecentsView {
    class ViewModel: ObservableObject {
        
        @Published var recents: [Components.Schemas.BlogPostModelV3] = []
        @Published var progresses: [String: Int] = [:]
        @Published var channelId: String?
        @Published var creatorId: String?
        
        private var offset = 0
        
        init(creatorId: String?, channelId: String?) {
            self.channelId = channelId
            self.creatorId = creatorId
        }
        
        /// Fetches and updates reading/viewing progress for a given post.
        func updateProgress(for postId: String) {
            Task {
               await fetchProgress(for: [postId])
            }
        }
        
        /// Fetches recent blog posts. If `refresh` is true, clears current results and restarts pagination.
        func fetchRecents(refresh: Bool = false) async {
            if refresh {
                offset = 0
                DispatchQueue.main.async {
                    self.recents.removeAll()
                }
            }
            
            do {
                // Fetch subscribed creators or a single creator
                let creators = try await fetchCreators()
                
                // Storage for results
                let perCreatorStorage = ItemStorage<[Components.Schemas.BlogPostModelV3]>()
                let flatStorage = ItemStorage<Components.Schemas.BlogPostModelV3>()
                
                // Fetch recents per creator concurrently
                let fetchTasks = creators.map { creator in
                    Task {
                        await self.fetchRecentForCreator(creator: creator, perCreatorStorage: perCreatorStorage)
                    }
                }
                for task in fetchTasks {
                    await task.value
               }
                
                // Once all creators are fetched, sort and store results
                let allRecents = await perCreatorStorage.getAll()
                let flattened = allRecents.flatMap { $0 }.sorted { $0.releaseDate > $1.releaseDate }
                
                // Fetch icons in parallel
                await fetchIcons(for: flattened)
                
                for recent in flattened {
                    await flatStorage.add(item: recent)
                }
                
                let sortedRecents = await flatStorage.getAll()
                
                // Update published properties on the main thread
                DispatchQueue.main.async {
                    self.recents.append(contentsOf: sortedRecents)
                    self.offset += 10
                }
                
            } catch {
                // Handle error appropriately
                print("Error fetching recents: \(error)")
            }
        }
        
        // MARK: - Private Helpers
        
        /// Fetches the relevant creators based on `creatorId` property.
        private func fetchCreators() async throws -> [Creator] {
            if let creatorId = creatorId {
                let creator = try await CreatorClient.shared.getCreator(id: creatorId)
                return [creator]
            } else {
                return try await CreatorClient.shared.getSubscribedCreators()
            }
        }
        
        /// Fetch recent blog posts for a single creator and store them.
        private func fetchRecentForCreator(
            creator: Creator,
            perCreatorStorage: ItemStorage<[Components.Schemas.BlogPostModelV3]>
        ) async {
            do {
                let query = Operations.getCreatorBlogPosts.Input.Query(
                    id: creator.id,
                    channel: channelId,
                    limit: 10,
                    fetchAfter: offset
                )
                
                let input = Operations.getCreatorBlogPosts.Input(query: query)
                let result = try await ApiService.shared.client.getCreatorBlogPosts(input)
                let recent = try result.ok.body.json
                
                // Filter results (example: only keep posts with video attachments)
                let filtered = recent.filter { !($0.videoAttachments ?? []).isEmpty }
                await perCreatorStorage.add(item: filtered)
                
                // Fetch progress for these recent posts
                await fetchProgress(for: recent.compactMap { $0.id })
                
            } catch {
                // Handle error appropriately
                print("Error fetching recents for creator \(creator.id): \(error)")
            }
        }
        
        /// Fetch progress for multiple post IDs.
        private func fetchProgress(for postIds: [String]) async {
            guard !postIds.isEmpty else { return }
            
            do {
                let body: Components.Schemas.GetProgressRequest = .init(ids: postIds, contentType: .blogPost)
                let progressResult = try await ApiService.shared.client.getProgress(body: .json(body))
                let fetchedProgresses = try progressResult.ok.body.json
                
                DispatchQueue.main.async {
                    for progress in fetchedProgresses {
                        self.progresses[progress.id] = progress.progress
                    }
                }
            } catch {
                // Handle error appropriately
                print("Error fetching progress for posts: \(error)")
            }
        }
        
        /// Fetch icons for a list of blog posts (if available).
        private func fetchIcons(for posts: [Components.Schemas.BlogPostModelV3]) async {
            await withTaskGroup(of: Void.self) { group in
                for post in posts {
                    if let thumbnail = post.thumbnail {
                        group.addTask {
                            IconService.shared.fetchIcon(url: thumbnail.value1.path)
                        }
                    }
                }
            }
        }
    }
}
