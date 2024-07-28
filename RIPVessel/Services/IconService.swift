//
//  IconService.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

//
//  IconService.swift
//  BKK
//
//  Created by RC MAC on 2022. 08. 05..
//  Copyright © 2022. realCity ITS Kft. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol IconServiceDelegate: AnyObject {
    func allIconsFetched()
}

class IconService: ObservableObject {
    public static let shared = IconService()
    
    @Published private(set) var pendingImages: [String: UIImage] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    var delegates: [IconServiceDelegate] = []
    
    private init() {}
    
    func fetchIcon(url: String) {
        
        guard let url = URL(string: url),
              let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        guard let finalURL = urlComponents.url else { return }
        
        let request = URLRequest(url: finalURL)
        
        if let data = URLCache.shared.cachedResponse(for: request)?.data {
            DispatchQueue.main.async {
                self.pendingImages[finalURL.absoluteString] = UIImage(data: data)
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
                   guard let response = response, let data = data, error == nil else {
                       DispatchQueue.main.async {
                           self.pendingImages[finalURL.absoluteString] = UIImage(data: Data())
                       }
                       return
                   }
                   
                   URLCache.shared.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                   DispatchQueue.main.async {
                       self.pendingImages[finalURL.absoluteString] = UIImage(data: data)
                       
                       if self.pendingImages.isEmpty {
                           self.delegates.forEach { $0.allIconsFetched() }
                           self.delegates.removeAll()
                       }
                   }
               }.resume()
    }
}
