//
//  VideoView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//


import SwiftUI

struct VideoView: View {
    @StateObject private var vm: ViewModel
    @State private var isRotated = false
    @State private var webViewHeight: CGFloat = .zero
    @Environment(\.scenePhase) var scenePhase
    @State private var isDescriptionExpanded: Bool = false
    
    init(post: Components.Schemas.BlogPostModelV3) {
        _vm = StateObject(wrappedValue: ViewModel(post: post))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isRotated ? .center : .top) {
                if let stream = vm.stream {
                    VideoPlayerWrapperView(
                        videoURL: (stream.groups.first?.origins?.first?.url ?? ""),
                        currentQuality: $vm.currentQuality,
                        qualities: vm.qualities,
                        size: geometry.size,
                        safeArea: geometry.safeAreaInsets,
                        isRotated: $isRotated,
                        title: vm.video?.title ?? ""
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                    .zIndex(10000)
                }
                ScrollView {
                    VStack {
                        Rectangle().aspectRatio(16/9, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height/3.5)
                            .opacity(0)
                        
                        HStack {
                            Text(vm.video?.title ?? "")
                                .font(.title)
                                .bold()
                                .padding()
                                .frame(alignment: .leading)
                            Spacer()
                        }
                        HStack {
                            Button {
                                vm.like()
                            } label: {
                                Image(systemName: (vm.post?.userInteraction?.contains(.like) ?? false) ? "hand.thumbsup.fill" : "hand.thumbsup")
                                Text(String(vm.post?.likes ?? 0))
                            }
                            Button {
                                vm.dislike()
                            } label: {
                                Image(systemName: (vm.post?.userInteraction?.contains(.dislike) ?? false) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                Text(String(vm.post?.dislikes ?? 0))
                            }
                            Spacer()
                        }.padding()
                        
                        CollapsibleAsyncAttributedTextView(htmlString: vm.description)
                            .padding()
                        
                        Spacer()
                    }
                    .onRotate { orientation in
                        if orientation == .portraitUpsideDown || orientation == .faceUp {
                            return
                        }
                        isRotated = orientation == .landscapeLeft || orientation == .landscapeRight
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .onAppear(perform: {
            AppDelegate.orientationLock = .allButUpsideDown
            AppDelegate.rotateScreen(to: .portrait)
        })
        .onChange(of: scenePhase, perform: { newPhase in
            if newPhase == .active {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                isRotated = false
            }
        })
        .persistentSystemOverlays(.hidden)
    }
}
