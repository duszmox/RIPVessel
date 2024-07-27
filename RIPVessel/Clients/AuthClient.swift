//
//  AuthClient.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import OpenAPIURLSession

public struct AuthClient {
    
    public init () {}
    
    public func getCaptcha() async throws -> String {
        let response = try await ApiService.shared.client.getCaptchaInfo()
        print("getCaptcha: \(response.hashValue)")
        return try response.ok.body.json.v3.variants.invisible.siteKey
    }
}
