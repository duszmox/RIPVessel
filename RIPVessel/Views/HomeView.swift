//
//  ContentView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var vm = ViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("Home")
                    .font(.title)
                    .padding()
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
            ScrollView {
                VStack(spacing: 16) {
                    if vm.creators.isEmpty {
                        Text("Loading...")
                            .font(.headline)
                    }
                    ForEach(vm.creators, id: \.id) { creator in
                        Text(creator.title)
                    }
                }
            }
            
            
        }.onAppear {
            Task {
                await vm.fetchCreators()
            }
        }
    }
}

#Preview {
    HomeView()
}
