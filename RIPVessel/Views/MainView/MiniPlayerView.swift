//
//  MiniPlayerView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 09..
//

import SwiftUI

struct MiniPlayerView: View {
    var size: CGSize
    @Binding var config: PlayerConfig
    var close: () -> Void

    /// Player Configuration
    let miniPlayerHeight: CGFloat = 50
    let playerHeight: CGFloat

    private var tabBarHeight: CGFloat {
        safeArea.bottom + 49
    }

    @StateObject private var vm: VideoView.ViewModel
    
    init(size: CGSize, config: Binding<PlayerConfig>, close: @escaping () -> Void, isRotated: Bool = false) {
        self.size = size
        _config = config
        self.close = close
        self.isRotated = isRotated
        _vm = .init(wrappedValue: VideoView.ViewModel(post: config.wrappedValue.selectedPlayerItem))
        self.playerHeight = size.width / 16 * 9
    }
    @State private var isRotated = false

    var body: some View {
        let progress = config.progress > 0.7 ? (config.progress - 0.7) / 0.3 : 0

        VStack(spacing: 0) {
            ZStack(alignment: isRotated ? .center : .top) {
                    if let stream = vm.stream {
                        GeometryReader {
                            let size = $0.size
                            let width = size.width - 120
                            let height = size.height
                            VideoPlayerWrapperView(
                                videoURL: stream.groups.first?.origins?.first?.url ?? "",
                                currentQuality: $vm.currentQuality,
                                qualities: vm.qualities,
                                size: size,
                                safeArea: EdgeInsets(
                                    top: safeArea.top,
                                    leading: safeArea.left,
                                    bottom: safeArea.bottom,
                                    trailing: safeArea.right
                                ),
                                isRotated: $isRotated,
                                title: vm.video?.title ?? "",
                                initialProgress: vm.video?.progress,
                                playerConfig: $config,
                                observeProgress: { p in
                                    vm.uploadProgress(p)
                                }
                            )
                            .frame(
                                width: 120 + (width - (width * progress)),
                                height: height)
                            .aspectRatio(16/9, contentMode: .fit)
                            .opacity(vm.isHidden ? 0 : 1)
                        }.zIndex(1)

                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(vm.video?.title ?? "")
                                .font(.callout)
                                .lineLimit(1)
                            Text(vm.post?.channel.title ?? "")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()

                        Button(action: {}, label: {
                            Image(systemName: "pause.fill")
                                .font(.title2)
                                .frame(width: 35, height: 35)
                        })

                        Button(action: close, label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .frame(width: 35, height: 35)
                        })
                    }
                    .padding(.leading, 130)
                    .padding(.trailing, 15)
                    .foregroundStyle(Color.primary)
                    .opacity(progress)
                
            }
            .frame(minHeight: miniPlayerHeight, maxHeight: playerHeight)
            .zIndex(1)
            .onRotate { orientation in
                if orientation == .portraitUpsideDown || orientation == .faceUp {
                    return
                }
                isRotated = orientation == .landscapeLeft || orientation == .landscapeRight
            }

            if let post = vm.post {
                ScrollView {
                    VStack {
                        HStack {
                            Text(vm.video?.title ?? "")
                                .font(.title)
                                .bold()
                                .padding()
                            Spacer()
                        }

                        HStack {
                            Button {
                                vm.like()
                            } label: {
                                Image(systemName: (post.userInteraction?.contains(.like) ?? false) ?
                                      "hand.thumbsup.fill" : "hand.thumbsup")
                                Text(String(post.likes))
                            }

                            Button {
                                vm.dislike()
                            } label: {
                                Image(systemName: (post.userInteraction?.contains(.dislike) ?? false) ?
                                      "hand.thumbsdown.fill" : "hand.thumbsdown")
                                Text(String(post.dislikes))
                            }
                            Spacer()
                        }
                        .padding()

                        CollapsibleAsyncAttributedTextView(htmlString: vm.description)
                            .padding()

                        Spacer()
                    }
                }
                .opacity(1.0 - (config.progress * 1.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background)
        .clipped()
        .contentShape(.rect)
        .offset(y: config.progress * -(safeArea.bottom + 49))
        .frame(height: size.height - config.position, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let start = value.startLocation.y
                    guard start < playerHeight || start > (size.height - (tabBarHeight+miniPlayerHeight)) else { return }

                    let height = config.lastPosition + value.translation.height
                    config.position = min(height, (size.height - miniPlayerHeight))
                    generateProgress(size: size)
                }
                .onEnded { value in
                    let start = value.startLocation.y
                    guard start < playerHeight || start > (size.height - (tabBarHeight+miniPlayerHeight)) else { return }

                    let velocity = value.velocity.height * 5
                    withAnimation(.smooth(duration: 0.3)) {
                        if (config.position + velocity) > (size.height * 0.65) {
                            config.position = (size.height - miniPlayerHeight)
                            config.lastPosition = config.position
                            config.progress = 1
                            AppDelegate.orientationLock = .portrait
                            AppDelegate.rotateScreen(to: .portrait)
                        } else {
                            AppDelegate.orientationLock = .allButUpsideDown
                            AppDelegate.rotateScreen(to: .portrait)
                            config.resetPosition()
                        }
                    }
                }.simultaneously(with: TapGesture().onEnded { _ in
                    withAnimation(.smooth(duration: 0.3)) {
                        AppDelegate.orientationLock = .allButUpsideDown
                        AppDelegate.rotateScreen(to: .portrait)
                        config.resetPosition()
                    }
                })
        )
        .transition(.offset(y: config.progress == 1 ? tabBarHeight : size.height))
        .onChange(of: config.selectedPlayerItem) { newValue in
            vm.updatePost(newValue)
            withAnimation(.smooth(duration: 0.3)) {
                config.resetPosition()
                AppDelegate.orientationLock = .allButUpsideDown
                AppDelegate.rotateScreen(to: .portrait)
            }
        }.onAppear {
            AppDelegate.orientationLock = .allButUpsideDown
            AppDelegate.rotateScreen(to: .portrait)
        }.onDisappear {
            AppDelegate.orientationLock = .portrait
            AppDelegate.rotateScreen(to: .portrait)
        }.ignoresSafeArea(isRotated ? .all : .container)
    }

    func generateProgress(size: CGSize) {
        let progress = max(min(config.position / (size.height - miniPlayerHeight), 1.0), .zero)
        config.progress = progress
    }
}
