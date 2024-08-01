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
        VStack {
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
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation") // Forcing the rotation to portrait
            AppDelegate.orientationLock = .portrait // And making sure it stays that way
        }.onDisappear {
            AppDelegate.orientationLock = .all // Unlocking the rotation when leaving the view
        }
    }
}
