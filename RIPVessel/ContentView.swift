//
//  ContentView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI
import SwiftData

struct ContentView: View {

    var body: some View {
        Button {
            Task {
                do {
                   try await AuthService.shared.logout()
                }
                catch {
                    print("Error: \(error)")
                }
            }
        } label: {
            Text(UserDefaultsService.shared.user!.id)
        }

    }

  
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
