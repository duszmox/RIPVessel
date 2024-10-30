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
    @State private var isRotated = false
    @State private var webViewHeight: CGFloat = .zero
    @Environment(\.scenePhase) var scenePhase

    
    init(post: Components.Schemas.BlogPostModelV3) {
        _vm = StateObject(wrappedValue: ViewModel(post: post))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isRotated ? .center : .top) {
                if let stream = vm.stream {
                    VideoPlayerWrapperView(videoURL: (stream.groups.first?.origins?.first?.url ?? ""),
                                           currentQuality: $vm.currentQuality,
                                           size: geometry.size,
                                           safeArea: geometry.safeAreaInsets,
                                           isRotated: $isRotated, title: vm.post.title)
                        .aspectRatio(16/9, contentMode: .fit)
                        .zIndex(10000)
                }
                ScrollView {
                    LazyVStack {
                        Rectangle().aspectRatio(16/9, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height/3.5)
                            .opacity(0)
                        
                        Text(vm.post.title)
                            .font(.title)
                            .bold()
                            .padding()
                        
                        AsyncAttributedTextView(htmlString: vm.post.text)
                        
                        Picker("Select Quality", selection: $vm.currentQuality) {
                            ForEach(vm.qualities, id: \.self) { quality in
                                Text(quality.label)
                                    .tag(quality as Components.Schemas.CdnDeliveryV3Variant)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        Spacer()
                    }
                    .onRotate { orientation in
                        isRotated = orientation == .landscapeLeft || orientation == .landscapeRight
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .onAppear {
            AppDelegate.orientationLock = .allButUpsideDown
        }
        .onChange(of: scenePhase, perform: { newPhase in
            if newPhase == .active {
                isRotated = !UIDevice.current.orientation.isPortrait
            }
        })
        .persistentSystemOverlays(.hidden)
    }
}
