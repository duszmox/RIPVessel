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
    var updateProgress: (String) -> Void
    
    init(post: Components.Schemas.BlogPostModelV3, updateProgress: @escaping (String) -> Void) {
        _vm = StateObject(wrappedValue: ViewModel(post: post))
        self.updateProgress = updateProgress
    }
    
    var body: some View {
        GeometryReader { geometry in
            let aspectWidth = CGFloat(vm.currentQuality?.meta?.video?.value2.width ?? 16)
            let aspectHeight = CGFloat(vm.currentQuality?.meta?.video?.value2.height ?? 9)
            let aspectRatio = aspectWidth / max(aspectHeight, .leastNonzeroMagnitude)
            let videoHeight = geometry.size.width / aspectRatio
            ZStack(alignment: .top) {
                if !isRotated {
                    Color.black
                        .frame(height: geometry.safeAreaInsets.top)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)
                }
                if let stream = vm.stream {
                    VideoPlayerWrapperView(
                        videoURL: (stream.groups.first?.origins?.first?.url ?? ""),
                        currentQuality: $vm.currentQuality,
                        qualities: vm.qualities,
                        size: geometry.size,
                        safeArea: geometry.safeAreaInsets,
                        isRotated: $isRotated,
                        title: vm.video?.title ?? "",
                        initialProgress: vm.video?.progress,
                        playerConfig: .constant(PlayerConfig()),
                        observeProgress: { p in
                            vm.uploadProgress(p)
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .top)
                    .zIndex(10000)
                }
                ScrollView {
                    VStack {
                        Rectangle()
                            .frame(width: geometry.size.width, height: videoHeight)
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
                }.frame(height: isRotated ? 0 : nil)
                .toolbar(.hidden, for: .tabBar)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(isRotated ? Color.black : Color(.systemBackground))
        }
        .ignoresSafeArea(edges: .top)
        .onAppear(perform: {
            AppDelegate.orientationLock = .allButUpsideDown
            AppDelegate.rotateScreen(to: .portrait)
        })
        .onDisappear {
            updateProgress(vm.post?.id ?? "")
        }
        .onChange(of: scenePhase, perform: { newPhase in
            if newPhase == .active {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                isRotated = false
            }
        })
        .persistentSystemOverlays(.hidden)
    }
}
