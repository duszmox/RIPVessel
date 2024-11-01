//
//  RecentPostView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//

import SwiftUI

struct RecentPostView: View {
    @StateObject private var vm: ViewModel
    @StateObject private var router = Router.shared

    init(post: Components.Schemas.BlogPostModelV3, isSpecificChannel: Bool = false) {
        _vm = StateObject(wrappedValue: ViewModel(post: post, isSpecificChannel: isSpecificChannel))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let thumbnail = vm.post.thumbnail?.value1.path {
                NavigationLink {
                    VideoView(post: vm.post)
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        IconView(url: thumbnail)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(8).padding([.leading, .trailing], 4)
                        HStack {
                            
                            if vm.post.metadata.hasVideo {
                                let text = vm.post.metadata.videoDuration.asString(style: .positional)
                                Text(text)
                                    .foregroundColor(.white).fontWeight(.semibold)
                                    .font(.system(size: 13))
                                    .padding(4)
                                    .background(Color.black.opacity(0.65))
                                    .cornerRadius(5)
                            }
                        }

                        .padding(8)
                    }
                }
            }
            
            HStack(alignment: .top, spacing: 10) {
                if let channel = vm.getChannelModel(from: vm.post.channel) {
                    NavigationLink {
                        ChannelView(id: channel.id, creatorId: vm.post.creator.id )
                    } label: {
                        IconView(url: channel.icon.path )
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }.disabled(self.vm.isSpecificChannel)
                } else {
                    IconView(url: vm.post.creator.icon.path )
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
               
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.post.title)
                        .font(.headline)
                        .lineLimit(2)
                        .padding(.top, 2)
                    
                    Text("\(vm.getChannelModel(from: vm.post.channel)?.title ?? "") • \(vm.post.releaseDate.timeAgoString())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            print("channel clicked")
                        }
                }
            }
            .padding([.horizontal, .bottom], 8)
        }.onTapGesture {
            if !(vm.post.videoAttachments?.isEmpty ?? true) {
                router.navigate(to: .video(post: vm.post))
            }
        }
    }
}
