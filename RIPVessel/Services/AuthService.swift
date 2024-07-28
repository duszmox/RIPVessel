//
//  AuthClient.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import OpenAPIURLSession
import Foundation

class AuthService: ObservableObject {
    
    static let shared: AuthService = AuthService()

    @Published var loggedIn: Bool = false
    
    private init() {
        loggedIn = UserDefaultsService.shared.user != nil
    }    
    
    func signIn(username: String, password: String) async throws  {
        let response = try await ApiService.shared.client.login(body: .json(Components.Schemas.AuthLoginV2Request(username: username, password: password)))
        do {
            let user = try response.ok.body.json.user
            DispatchQueue.main.async {
               UserDefaultsService.shared.user = user
               self.loggedIn = true
           }
        }
        catch {
            throw error
        }
    }
    
    func logout() async throws {
        _ = try await ApiService.shared.client.logout()
        DispatchQueue.main.async {
            UserDefaultsService.shared.user = nil
            self.loggedIn = false
        }
    }
}
