//
//  ApiService.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//
import OpenAPIURLSession

public class ApiService {
    
    public static let shared = ApiService()
    
    let client: Client;
    
    public init() {
        do {
            client = Client(
                serverURL: try Servers.server1(),
                transport: URLSessionTransport()
            )
        }
        catch {
            fatalError("Failed to create client: \(error)")
        }
    }
    
}
