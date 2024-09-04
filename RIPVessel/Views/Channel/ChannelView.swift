//
//  ChannelView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 08. 18..
//

import SwiftUI

struct ChannelView: View {
    let id: String
    @StateObject var vm: ViewModel
    
    init(id: String, creator: Components.Schemas.CreatorModelV3) {
        self.id = id
        _vm = .init(wrappedValue: ViewModel(creator: creator, channelId: id))
        
    }
    
    var body: some View {
        if !vm.creator.channels.contains(where: {$0.id == self.id}) {
            LoadingView()
            
        } else {
            VStack (alignment: .leading) {
                ScrollView {
                    ZStack {
                        IconView(url: vm.creator.channels.first(where: {$0.id == id })!.cover!.value1.path).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).aspectRatio(1.77777, contentMode: .fit)
                        HStack {
                            IconView(url: vm.creator.channels.first(where: {$0.id == id })!.icon.path).frame(width: 40, height: 40, alignment: .leading).clipShape(Circle())
                            Text(vm.creator.channels.first(where: {$0.id == id })!.title)
                                .font(.headline)
                                .foregroundColor(.white)
                        }.frame(alignment: .leading)
                    }
                    RecentsView(creatorId: self.vm.creator.id, channelId: id, scrollEnabled: .constant(false))
                }
            }.frame(maxHeight: .infinity)
        }
       
    }
}
