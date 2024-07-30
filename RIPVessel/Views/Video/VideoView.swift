//
//  VideoView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//


import SwiftUI
import AVKit

struct VideoView: View {
    @StateObject private var vm: ViewModel
    
    init(post: Components.Schemas.BlogPostModelV3) {
        _vm = StateObject(wrappedValue: ViewModel(post: post))
    }
    
    var body: some View {
        GeometryReader { geometry in
            
       
        VStack {
            if let stream = vm.stream {
                ZStack {
                    VideoPlayerWrapperView(videoURL: (stream.groups.first?.origins?.first?.url ?? ""), currentQuality: $vm.currentQuality, size: geometry.size, safeArea: geometry.safeAreaInsets)
                        .aspectRatio(16/9, contentMode: .fit)
                }
            }
            Text(vm.post.title)
                .font(.title)
                .bold()
                .padding()
            Text(vm.post.text)
                
            Picker("Select Quality", selection: $vm.currentQuality) {
                ForEach(vm.qualities, id: \.self) { quality in
                    Text(quality.label).tag(quality as Components.Schemas.CdnDeliveryV3Variant)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            Spacer()
        }
        .onAppear {
            print("VideoView")
        }
        .navigationBarBackButtonHidden(false)
        }
    }
}


//#Preview {
//    VideoView()
//}
