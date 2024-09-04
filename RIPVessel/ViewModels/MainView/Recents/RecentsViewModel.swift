//
//  RecentsViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import Foundation

extension RecentsView {
    class ViewModel: ObservableObject {
        @Published var recents: [Components.Schemas.BlogPostModelV3] = []
        @Published var channelId: String?
        @Published var creatorId: String?
        private var offset = 0
        
        init(creatorId: String?, channelId: String?) {
            if let channelId {
                self.channelId = channelId
            }
            if let creatorId {
                self.creatorId = creatorId
            }
        }
        
        func fetchRecents(refresh: Bool = false) async {
            do {
                let recentsPerCreatorStorage = ItemStorage<[Components.Schemas.BlogPostModelV3]>()
                let recentsStorageFlat = ItemStorage<Components.Schemas.BlogPostModelV3>()
                let creators = creatorId != nil ? [try await CreatorClient.shared.getCreator(id: creatorId!)] : try await CreatorClient.shared.getSubscribedCreators()
                var tasks = [Task<Void, Never>]()

                if refresh {
                    offset = 0
                    DispatchQueue.main.async {
                        self.recents = []
                    }
                }
                for creator in creators {
                    let task = Task {
                        do {
                            let recentResult = try await ApiService.shared.client.getCreatorBlogPosts(
                                Operations.getCreatorBlogPosts.Input(query: Operations.getCreatorBlogPosts.Input.Query(id: creator.id, channel: channelId, limit: 10, fetchAfter: offset))
                            )
                            print("Recent: \(recentResult)")
                            let recent = try recentResult.ok.body.json
                            await recentsPerCreatorStorage.add(item: recent)
                        } catch {
                            print("Error fetching creator: \(error)")
                        }
                    }
                    tasks.append(task)
                }

                for task in tasks {
                    await task.value
                }

                let allRecents = await recentsPerCreatorStorage.getAll()
                var flattenedRecents = allRecents.flatMap { $0 }
                flattenedRecents.sort { $0.releaseDate > $1.releaseDate }

                for recent in flattenedRecents {
                    if let thubnail = recent.thumbnail {
                        IconService.shared.fetchIcon(url: thubnail.value1.path)
                    }
                    await recentsStorageFlat.add(item: recent)
                }

                let sortedRecents = await recentsStorageFlat.getAll()
                DispatchQueue.main.async {
                    self.recents.append(contentsOf: sortedRecents)
                    self.offset += 10
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
