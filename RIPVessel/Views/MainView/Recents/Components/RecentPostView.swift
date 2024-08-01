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

    init(post: Components.Schemas.BlogPostModelV3) {
        _vm = StateObject(wrappedValue: ViewModel(post: post))
    }
    
    var body: some View {
            VStack {
                if vm.post.thumbnail != nil {
                    ZStack(alignment: .bottomTrailing) {
                        IconView(url: vm.post.thumbnail!.value1.path)
                            .aspectRatio(16/9, contentMode: .fit)
                        
                        HStack {
                            if !(vm.post.galleryAttachments?.isEmpty ?? true) {
                                Image(systemName: "photo.artframe")
                            }
                            if !(vm.post.videoAttachments?.isEmpty ?? true) {
                                Image(systemName: "video")
                            }
                            if !(vm.post.audioAttachments?.isEmpty ?? true) {
                                Image(systemName: "waveform")
                            }
                            if !(vm.post.pictureAttachments?.isEmpty ?? true) {
                                Image(systemName: "photo.fill")
                            }
                        }
                        .padding(10)
                        .background(Color(.gray).opacity(0.65))
                        .cornerRadius(20)
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                }
                Text(vm.post.title)
            }.onTapGesture {
                if !(vm.post.videoAttachments?.isEmpty ?? true) {
                    router.navigate(to: .video(post: vm.post))
                }
            }
    }
}

//#Preview {
//    RecentPostView()
//}
