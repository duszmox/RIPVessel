//
//  CreatorClient.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//
import Foundation

class CreatorClient {
    
    static let shared: CreatorClient = CreatorClient()

    
    func getCreators() async throws -> [Components.Schemas.CreatorModelV3] {
            // TODO: Open an issue to have it set to optional
            let result = try await ApiService.shared.client.getCreators(Operations.getCreators.Input(query: Operations.getCreators.Input.Query(search: "")))
            let c = try result.ok.body.json
            return c
    }
    
    func getSubscribedCreators() async throws -> [Components.Schemas.CreatorModelV3] {
        let creatorsStorage = ItemStorage<Components.Schemas.CreatorModelV3>()
        let result = try await ApiService.shared.client.listUserSubscriptionsV3()
        let c = try result.ok.body.json
        var tasks = [Task<Void, Never>]()
        
        for sub in c {
            let task = Task {
                do {
                    let creatorResult = try await ApiService.shared.client.getCreator(Operations.getCreator.Input(query: Operations.getCreator.Input.Query(id: sub.creator)))
                    let creator = try creatorResult.ok.body.json
                    await creatorsStorage.add(item: creator)
                } catch {
                    print("Error fetching creator: \(error)")
                }
            }
            tasks.append(task)
        }
        
        for task in tasks {
            await task.value
        }
        
        return await creatorsStorage.getAll()
        
    }
    
    func getCreator(id: String) async throws -> Components.Schemas.CreatorModelV3 {
        let result = try await ApiService.shared.client.getCreator(Operations.getCreator.Input(query: Operations.getCreator.Input.Query(id: id)))
        let creator = try result.ok.body.json
        return creator
    }
}
