//
//  VideoPlayerWrapperView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 30..
//

import SwiftUI
import AVFoundation

struct VideoPlayerWrapperView: View {
    @State private var isPlaying = false
    @State private var isBuffering = false
    @State private var showPlayerControls = false
    @State private var timeoutTask: DispatchWorkItem?
    @GestureState private var isDragging = false
    @State private var isSeeking = false
    @State private var isFinishedPlaying = false
    @State private var progress: CGFloat = 0
    @State private var lastDraggedValue: CGFloat = 0
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isObserverAdded: Bool = false
    @Binding private var playerConfig: PlayerConfig
    let initialProgress: Int?

    let videoURL: String
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @State var size: CGSize
    @State var safeArea: EdgeInsets
    @State var title: String
    @Binding var isRotated: Bool

    @State private var showQualitySheet = false
    let qualities: [Components.Schemas.CdnDeliveryV3Variant]

    @StateObject private var vm: PlayerViewModel
    var observeProgress: (Double) -> Void

    init(
        videoURL: String,
        currentQuality: Binding<Components.Schemas.CdnDeliveryV3Variant?>,
        qualities: [Components.Schemas.CdnDeliveryV3Variant],
        size: CGSize = .zero,
        safeArea: EdgeInsets = .init(),
        isRotated: Binding<Bool>,
        title: String,
        initialProgress: Int?,
        playerConfig: Binding<PlayerConfig>,
        observeProgress: @escaping (Double) -> Void
    ) {
        self.videoURL = videoURL
        self.size = size
        self.safeArea = safeArea
        _isRotated = isRotated
        _currentQuality = currentQuality
        self.title = title
        self.qualities = qualities
        let url = URL(string: videoURL + (currentQuality.wrappedValue?.url ?? ""))!
        _vm = StateObject(wrappedValue: PlayerViewModel(url: url))
        self.observeProgress = observeProgress
        self.initialProgress = initialProgress
        _playerConfig = playerConfig
    }

    var body: some View {
        let videoPlayerSize: CGSize = .init(
            width: isRotated ? size.height + safeArea.bottom + safeArea.top : size.width,
            height: isRotated ? size.width + safeArea.leading + safeArea.trailing : .zero
        )

        ZStack(alignment: .center) {
            VideoPlayerView(
                url: URL(string: videoURL)!,
                play: $isPlaying,
                currentQuality: $currentQuality,
                isBuffering: $isBuffering,
                player: vm.player,
                progress: $progress,
                initialProgress: initialProgress,
                observeProgress: observeProgress
            )
            .overlay {
                videoOverlays
            }
            .onTapGesture {
                guard playerConfig.progress != 1 else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    showPlayerControls.toggle()
                }
                if isPlaying {
                    timeoutControls()
                }
            }
            .overlay(alignment: .bottom) {
                VideoSeekerView(
                    progress: $progress,
                    isDragging: isDragging,
                    isSeeking: $isSeeking,
                    lastDraggedValue: $lastDraggedValue,
                    currentTime: $currentTime,
                    duration: $duration,
                    showPlayerControls: $showPlayerControls,
                    isRotated: isRotated,
                    size: size,
                    seekAction: { newProgress in
                        if let currentPlayerItem = vm.player.currentItem {
                            let totalDuration = currentPlayerItem.duration.seconds
                            currentTime = newProgress * totalDuration
                            vm.player.seek(to: .init(seconds: totalDuration * newProgress, preferredTimescale: 1))
                            if isPlaying {
                                timeoutControls()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isSeeking = false
                            }
                        }
                    }
                )
                .offset(y: isRotated ? -15 : 0)
            }
            .overlay(alignment: .bottom) {
                BottomControlsView(
                    currentTime: $currentTime,
                    duration: $duration,
                    isRotated: $isRotated,
                    showPlayerControls: $showPlayerControls,
                    isSeeking: $isSeeking,
                    size: size,
                    safeArea: safeArea,
                    toggleRotation: toggleRotation
                )
                .offset(y: isRotated ? -15 : 0)
            }
            .overlay(alignment: .top) {
                TopControlsView(
                    title: title,
                    showPlayerControls: $showPlayerControls,
                    isRotated: isRotated,
                    safeArea: safeArea
                )
                .padding(.top, 10)
                .padding(.leading, 10)
            }
            .overlay(alignment: .topTrailing) {
                if showPlayerControls {
                    Button(action: {
                        showQualitySheet.toggle()
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding()
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
            }
        }
        .background {
            Rectangle().fill(Color.black)
        }
//        .gesture(
//            DragGesture().onEnded { value in
//                if -value.translation.height > 100 {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        isRotated = true
//                    }
//                    AppDelegate.rotateScreen(to: .landscape)
//                } else {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        isRotated = false
//                    }
//                    AppDelegate.rotateScreen(to: .portrait)
//                }
//            }
//        )
        .frame(width: videoPlayerSize.width, height: isRotated ? videoPlayerSize.height : nil)
        .frame(width: size.width)
        .zIndex(10000)
        .onChange(of: currentQuality) { newQuality in
            let newURL = URL(string: videoURL + (newQuality?.url ?? ""))!
            let currentTime = vm.player.currentTime().seconds
            vm.updatePlayerItem(url: newURL)
            vm.player.seek(to: .init(seconds: currentTime, preferredTimescale: 1))
        }
        .onChange(of: playerConfig.progress) { newProgress in
            if newProgress >= 1 || newProgress <= 0 {
                showPlayerControls = false
            }
        }
        .onAppear {
            AppDelegate.orientationLock = .allButUpsideDown
            setupPlayerObserver()
            isPlaying.toggle()
        }
        .onDisappear {
            vm.player.pause()
        }
        .navigationBarBackButtonHidden(isRotated)
        .sheet(isPresented: $showQualitySheet) {
            QualitySelectionSheet(
                qualities: qualities,
                currentQuality: $currentQuality,
                isPresented: $showQualitySheet
            )
        }
    }

    // MARK: - Overlays

    private var videoOverlays: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .opacity(showPlayerControls || isDragging ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: isDragging)
            HStack(spacing: 60) {
                DoubleTapSeek {
                    showPlayerControls = false
                    seek(by: -10)
                }
                DoubleTapSeek(isForward: true) {
                    showPlayerControls = false
                    seek(by: 10)
                }
            }
            PlayerControlsView(
                isPlaying: $isPlaying,
                isFinishedPlaying: $isFinishedPlaying,
                isBuffering: $isBuffering,
                showPlayerControls: $showPlayerControls,
                isDragging: isDragging,
                seekBackward: { seek(by: -10) },
                seekForward: { seek(by: 10) },
                playPauseAction: playPauseAction
            )
        }
    }

    // MARK: - Functions

    func setupPlayerObserver() {
        guard !isObserverAdded else { return }
        vm.player.addPeriodicTimeObserver(
            forInterval: .init(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { time in
            if let currentPlayerItem = vm.player.currentItem {
                let totalDuration = currentPlayerItem.duration.seconds
                let currentDuration = vm.player.currentTime().seconds
                let calculatedProgress = currentDuration / totalDuration
                if !isSeeking {
                    progress = calculatedProgress
                    lastDraggedValue = calculatedProgress
                }
                if calculatedProgress >= 1.0 {
                    isFinishedPlaying = true
                }
                currentTime = currentDuration
                duration = totalDuration.isNaN ? 0 : totalDuration
            }
        }
        isObserverAdded = true
    }

    func seek(by seconds: Double) {
        if let currentPlayerItem = vm.player.currentItem {
            let totalDuration = currentPlayerItem.duration.seconds
            let currentDuration = vm.player.currentTime().seconds
            var newTime = currentDuration + seconds
            if newTime < 0 {
                newTime = 0
            } else if newTime > totalDuration {
                newTime = totalDuration
                isFinishedPlaying = true
                isPlaying = false
            }
            let newProgress = newTime / totalDuration
            progress = newProgress
            lastDraggedValue = newProgress
            vm.player.seek(to: .init(seconds: newTime, preferredTimescale: 1))
            if isPlaying {
                timeoutControls()
            }
        }
    }

    func timeoutControls() {
        timeoutTask?.cancel()
        timeoutTask = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.35)) {
                showPlayerControls = false
            }
        }
        if let timeoutTask = timeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutTask)
        }
    }

    func toggleRotation() {
        if isRotated {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRotated = false
            }
            AppDelegate.rotateScreen(to: .portrait)
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRotated = true
            }
            AppDelegate.rotateScreen(to: .landscape)
        }
    }

    func playPauseAction() {
        withAnimation(.easeOut(duration: 0.2)) {
            if isFinishedPlaying {
                isFinishedPlaying = false
                vm.player.seek(to: CMTime.zero)
                progress = .zero
                lastDraggedValue = .zero
            }
            if isPlaying {
                timeoutTask?.cancel()
            } else {
                timeoutControls()
            }
            isPlaying.toggle()
        }
    }
}
