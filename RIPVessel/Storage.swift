//
//  Storage.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

actor ItemStorage<T> {
    private var items = [T]()
    
    func add(item: T) {
        items.append(item)
    }
    
    func getAll() -> [T] {
        return items
    }
}
