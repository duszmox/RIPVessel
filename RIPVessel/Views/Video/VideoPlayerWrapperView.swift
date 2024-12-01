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

    // Properties passed in
    let videoURL: String
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @State var size: CGSize
    @State var safeArea: EdgeInsets
    @State var title: String
    @Binding var isRotated: Bool

    // Use @StateObject for PlayerViewModel
    @StateObject private var playerViewModel: PlayerViewModel

    init(
        videoURL: String,
        currentQuality: Binding<Components.Schemas.CdnDeliveryV3Variant?>,
        size: CGSize = .zero,
        safeArea: EdgeInsets = .init(),
        isRotated: Binding<Bool>,
        title: String
    ) {
        self.videoURL = videoURL
        _currentQuality = currentQuality
        self.size = size
        self.safeArea = safeArea
        _isRotated = isRotated
        self.title = title

        let url = URL(string: videoURL + (currentQuality.wrappedValue?.url ?? ""))!
        _playerViewModel = StateObject(wrappedValue: PlayerViewModel(url: url))
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
                player: playerViewModel.player,
                progress: $progress
            )
            .overlay {
                videoOverlays
            }
            .onTapGesture {
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
                        if let currentPlayerItem = playerViewModel.player.currentItem {
                            let totalDuration = currentPlayerItem.duration.seconds
                            currentTime = newProgress * totalDuration
                            playerViewModel.player.seek(to: .init(seconds: totalDuration * newProgress, preferredTimescale: 1))
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
            }
        }
        .background {
            Rectangle().fill(Color.black)
        }
        .gesture(
            DragGesture().onEnded { value in
                if -value.translation.height > 100 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRotated = true
                    }
                    rotateScreen(to: .landscape)
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRotated = false
                    }
                    rotateScreen(to: .portrait)
                }
            }
        )
        .frame(width: videoPlayerSize.width, height: isRotated ? videoPlayerSize.height : nil)
        .frame(width: size.width)
        .zIndex(10000)
        .onChange(of: currentQuality) { newQuality in
            let newURL = URL(string: videoURL + (newQuality?.url ?? ""))!
            playerViewModel.updatePlayerItem(url: newURL)
        }
        .onAppear {
            AppDelegate.orientationLock = .allButUpsideDown
            setupPlayerObserver()
            isPlaying.toggle()
        }
        .onDisappear {
            playerViewModel.player.pause()
        }
        .navigationBarBackButtonHidden(isRotated)
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
                playPauseAction: playPauseAction // Added back
            )
        }
    }

    // MARK: - Functions

    func setupPlayerObserver() {
        guard !isObserverAdded else { return }
        playerViewModel.player.addPeriodicTimeObserver(
            forInterval: .init(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { time in
            if let currentPlayerItem = playerViewModel.player.currentItem {
                let totalDuration = currentPlayerItem.duration.seconds
                let currentDuration = playerViewModel.player.currentTime().seconds
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
        if let currentPlayerItem = playerViewModel.player.currentItem {
            let totalDuration = currentPlayerItem.duration.seconds
            let currentDuration = playerViewModel.player.currentTime().seconds
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
            playerViewModel.player.seek(to: .init(seconds: newTime, preferredTimescale: 1))
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
            rotateScreen(to: .portrait)
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRotated = true
            }
            rotateScreen(to: .landscape)
        }
    }

    func rotateScreen(to orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
            print("Error updating geometry: \(error)")
        }
    }

    func playPauseAction() {
        withAnimation(.easeOut(duration: 0.2)) {
            if isFinishedPlaying {
                isFinishedPlaying = false
                playerViewModel.player.seek(to: CMTime.zero)
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
