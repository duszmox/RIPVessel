//
//  ContentView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI
import SwiftData

struct CreatorsView: View {
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
                VStack(alignment: .leading, spacing: 16) {
                    if vm.creators.isEmpty {
                        Text("Loading...")
                            .font(.headline)
                    }
                    ForEach(vm.creators, id: \.id) { creator in
                        HStack {
                            IconView(url: creator.icon.path, size: CGSize(width: 44, height: 44)).clipShape(Circle())
                            Text(creator.title)
                        }
                        ForEach(creator.channels, id: \.id) { channel in
                            HStack {
                                NavigationLink {
                                    ChannelView(id: channel.id, creator: creator)
                                } label: {
                                    IconView(url: channel.icon.path, size: CGSize(width: 33, height: 33)).clipShape(Circle())
                                    Text(channel.title)
                                }
                               
                            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        }
                    }
                }
            }.frame(alignment: .leading)
            
            
        }.onAppear {
            Task {
                await vm.fetchSubscriptions()
            }
        }
    }
}

#Preview {
    CreatorsView()
}
