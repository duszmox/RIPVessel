//
//  RecentsView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import SwiftUI

struct RecentsView: View {
    @StateObject private var vm = ViewModel()
    
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
        ScrollView {
            LazyVStack {
                if vm.recents.isEmpty {
                    Text("Loading...")
                        .font(.headline)
                }
                ForEach(vm.recents, id: \.id) { recent in
                    RecentPostView(post: recent)
                        .onAppear {
                        Task {
                            if recent.id == vm.recents.last?.id {
                                await vm.fetchRecents()
                            }
                        }
                    }
                }
            }
        }.onAppear {
            Task {
                await vm.fetchRecents()
            }
        }.refreshable {
            Task {
                await vm.fetchRecents(refresh: true)
            }
        }
    }
}

#Preview {
    RecentsView()
}
