//
//  MiniPlayerView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 09..
//

import SwiftUI

// MARK: - Main MiniPlayerView

struct MiniPlayerView: View {
    var size: CGSize
    @Binding var config: PlayerConfig
    var close: () -> Void

    // Fixed sizes and computed heights
    private let collapsedVideoWidth: CGFloat = 120
    let miniPlayerHeight: CGFloat
    let playerHeight: CGFloat
    private var tabBarHeight: CGFloat {
        safeArea.bottom + CGFloat(49)
    }

    @StateObject private var vm: VideoView.ViewModel
    @State private var isRotated = false

    init(size: CGSize, config: Binding<PlayerConfig>, close: @escaping () -> Void, isRotated: Bool = false) {
        self.size = size
        _config = config
        self.close = close
        self.isRotated = isRotated
        self.miniPlayerHeight = collapsedVideoWidth * (CGFloat(9) / CGFloat(16))
        // Instantiate the view model using the selected player item
        _vm = StateObject(wrappedValue: VideoView.ViewModel(post: config.wrappedValue.selectedPlayerItem))
        self.playerHeight = size.width * (CGFloat(9) / CGFloat(16))
    }

    var body: some View {
        GeometryReader { geometry in
            // Compute progress values that drive the mini player layout and overlays
            let clampedProgress: CGFloat = max(min(config.progress, CGFloat(1)), CGFloat(0))
            let overlayProgress: CGFloat = clampedProgress > CGFloat(0.7) ? (clampedProgress - CGFloat(0.7)) / CGFloat(0.3) : 0

            VStack(spacing: 0) {
                // Top section: video content + overlay controls
                ZStack(alignment: isRotated ? .center : .top) {
                    MiniPlayerVideoContentView(
                        stream: vm.stream,
                        geometry: geometry,
                        progress: clampedProgress,
                        collapsedWidth: collapsedVideoWidth,
                        collapsedHeight: miniPlayerHeight,
                        isRotated: $isRotated,
                        vm: vm,
                        config: $config,
                    )
                    MiniPlayerOverlayView(
                        vm: vm,
                        close: close,
                        progress: overlayProgress,
                        collapsedWidth: collapsedVideoWidth
                    )
                }
                .frame(minHeight: miniPlayerHeight, maxHeight: playerHeight)
                .zIndex(1)
                .onRotate { orientation in
                    // Ignore upside-down and face-up orientations
                    if orientation == .portraitUpsideDown || orientation == .faceUp { return }
                    isRotated = orientation == .landscapeLeft || orientation == .landscapeRight
                }

                // Bottom section: detailed view (scrollable)
                MiniPlayerDetailView(
                    vm: vm,
                    isRotated: isRotated,
                    progress: clampedProgress
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(isRotated ? Color.black : Color(.systemBackground))
            .clipped()
            .contentShape(Rectangle())
            .offset(y: config.progress * -(safeArea.bottom + CGFloat(49)))
            .frame(height: geometry.size.height - config.position, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let start = value.startLocation.y
                        let canDragFromStart = isRotated ||
                        start < playerHeight ||
                        start > (geometry.size.height - (tabBarHeight + miniPlayerHeight))
                        // Ensure the gesture only triggers in the top or bottom regions
                        guard canDragFromStart
                        else { return }
                        if isRotated {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRotated = false
                            }
                            AppDelegate.rotateScreen(to: .portrait)
                        }
                        let height = config.lastPosition + value.translation.height
                        let clampedHeight = max(.zero, min(height, geometry.size.height - miniPlayerHeight))
                        config.position = clampedHeight
                        generateProgress(size: geometry.size)
                    }
                    .onEnded { value in
                        let start = value.startLocation.y
                        let canDragFromStart = isRotated ||
                        start < playerHeight ||
                        start > (geometry.size.height - (tabBarHeight + miniPlayerHeight))
                        guard canDragFromStart
                        else { return }
                        let velocity = value.velocity.height * CGFloat(5)
                        withAnimation(.smooth(duration: 0.3)) {
                            if (config.position + velocity) > (geometry.size.height * CGFloat(0.65)) {
                                if isRotated {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isRotated = false
                                    }
                                    AppDelegate.rotateScreen(to: .portrait)
                                }
                                config.position = (geometry.size.height - miniPlayerHeight)
                                config.lastPosition = config.position
                                config.progress = CGFloat(1)
                            } else {
                                config.resetPosition()
                            }
                        }
                    }
                    .simultaneously(with: TapGesture().onEnded { _ in
                        withAnimation(.smooth(duration: 0.3)) {
                            AppDelegate.orientationLock = .allButUpsideDown
                            AppDelegate.rotateScreen(to: .portrait)
                            config.resetPosition()
                        }
                    })
            )
            .transition(.offset(y: config.progress == CGFloat(1) ? tabBarHeight : geometry.size.height))
            .onChange(of: config.selectedPlayerItem) { newValue in
                vm.updatePost(newValue)
                withAnimation(.smooth(duration: 0.3)) {
                    config.resetPosition()
                    AppDelegate.orientationLock = .allButUpsideDown
                    AppDelegate.rotateScreen(to: .portrait)
                }
            }
            .onAppear {
                AppDelegate.orientationLock = .allButUpsideDown
                AppDelegate.rotateScreen(to: .portrait)
            }
            .onDisappear {
                AppDelegate.orientationLock = .portrait
                AppDelegate.rotateScreen(to: .portrait)
            }
            .ignoresSafeArea(isRotated ? .all : .container)
        }
    }

    // Helper method for updating the progress based on drag gesture and available height.
    func generateProgress(size: CGSize) {
        let progress = max(min(config.position / (size.height - miniPlayerHeight), CGFloat(1)), .zero)
        config.progress = progress
    }
}

// MARK: - Subview: Video Content

struct MiniPlayerVideoContentView: View {
    var stream: Components.Schemas.CdnDeliveryV3Response?
    var geometry: GeometryProxy
    var progress: CGFloat
    var collapsedWidth: CGFloat
    var collapsedHeight: CGFloat
    @Binding var isRotated: Bool
    @ObservedObject var vm: VideoView.ViewModel
    @Binding var config: PlayerConfig

    var body: some View {
        if let stream = stream {
            let size = geometry.size
            let expandedWidth = size.width
            let expandedHeight = size.width * (CGFloat(9) / CGFloat(16))
            let videoWidth = expandedWidth - (expandedWidth - collapsedWidth) * progress
            let videoHeight = expandedHeight - (expandedHeight - collapsedHeight) * progress
            let alignment: Alignment = isRotated ? .center : .leading

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
            .frame(width: videoWidth, height: videoHeight)
            .opacity(vm.isHidden ? 0 : 1)
            .frame(
                maxWidth: .infinity,
                maxHeight: isRotated ? .infinity : nil,
                alignment: alignment
            )
        }
    }
}

// MARK: - Subview: Overlay (Title and Controls)

struct MiniPlayerOverlayView: View {
    @ObservedObject var vm: VideoView.ViewModel
    var close: () -> Void
    var progress: CGFloat
    var collapsedWidth: CGFloat

    var body: some View {
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
        .padding(.leading, collapsedWidth + CGFloat(10))
        .padding(.trailing, CGFloat(15))
        .foregroundStyle(Color.primary)
        .opacity(progress)
    }
}

// MARK: - Subview: Details

struct MiniPlayerDetailView: View {
    @ObservedObject var vm: VideoView.ViewModel
    let isRotated: Bool
    let progress: CGFloat

    var body: some View {
        if let post = vm.post {
            let detailOpacity = max(CGFloat.zero, CGFloat(1) - (progress * CGFloat(1.6)))
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
                            Image(systemName: (post.userInteraction?.contains(.like) ?? false)
                                  ? "hand.thumbsup.fill" : "hand.thumbsup")
                            Text(String(post.likes))
                        }
                        Button {
                            vm.dislike()
                        } label: {
                            Image(systemName: (post.userInteraction?.contains(.dislike) ?? false)
                                  ? "hand.thumbsdown.fill" : "hand.thumbsdown")
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
            // Hide the detail view when rotated; adjust opacity with progress.
            .frame(height: isRotated ? CGFloat.zero : nil)
            .opacity(detailOpacity)
        }
    }
}
