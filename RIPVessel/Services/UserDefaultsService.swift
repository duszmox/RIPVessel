//
//  UserDefaultsService.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import Foundation

public class UserDefaultsService {
    
    enum Keys: String {
        case user = "kUser"
    }
    
    public static let shared = UserDefaultsService()
    
    // MARK: Stored Variables
    
    var user: Components.Schemas.UserModel? {
        get {
            try? decodable(for: Keys.user.rawValue)
        }
        set {
            try? setEncodable(newValue, for: Keys.user.rawValue)
        }
    }
    
    // MARK: Private Utils
    
    private func decodable<T: Decodable>(for key: String) throws -> T? {
        let rawData = UserDefaults.standard.data(forKey: key)
        
        if rawData == nil {
            return nil
        }
        
        return try JSONDecoder().decode(T.self, from: rawData!)
    }
    
    private func setEncodable<T: Encodable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func valueExists(for key: String) -> Bool {
        UserDefaults.standard.object(forKey: key) != nil
    }
    
    // MARK: Public utils
    
    func delete(key: Keys) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
    
}
