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
    
    @State var videoURL: String
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @State var player: AVPlayer
    
    @State private var timeoutTask: DispatchWorkItem?
    
    @GestureState private var isDragging = false
    @State private var isSeeking = false
    @State private var isFinishedPlaying = false
    @State private var progress: CGFloat = 0
    @State private var lastDraggedValue: CGFloat = 0
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    
    @State var size: CGSize
    @State var safeArea: EdgeInsets
    
    @State private var isObserverAdded: Bool = false
    
    @Binding private var isRotated: Bool
    init(videoURL: String, currentQuality: Binding<Components.Schemas.CdnDeliveryV3Variant?>, size: CGSize = .zero, safeArea: EdgeInsets = .init(), isRotated: Binding<Bool>) {
        
        self.videoURL = videoURL
        _currentQuality = currentQuality
        
        self.size = size
        self.safeArea = safeArea
        let asset = AVURLAsset(url: URL(string: videoURL + (currentQuality.wrappedValue?.url ?? ""))!, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true, AVURLAssetHTTPCookiesKey: HTTPCookieStorage.shared.cookies as Any])
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        self.player = player
        _isRotated = isRotated
    }
    
    var body: some View {
        let videoPlayerSize: CGSize = .init(width: isRotated ? size.height+safeArea.bottom+safeArea.top : size.width, height: isRotated ? size.width+safeArea.leading+safeArea.trailing : (size.height/3.5))
        ZStack(alignment: .center) {
            VideoPlayerView(url: URL(string: videoURL)!, play: $isPlaying, currentQuality: $currentQuality, isBuffering: $isBuffering, player: player, progress: $progress).overlay {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .opacity(showPlayerControls || isDragging ? 1 : 0)
                    .animation(.easeInOut(duration: 0.35), value: isDragging)
                    .overlay(content: {
                        HStack (spacing: 60) {
                            DoubleTapSeek {
                                showPlayerControls = false
                                seek(by: -10)
                            }
                            DoubleTapSeek(isForward: true) {
                                showPlayerControls = false
                                seek(by: 10)
                            }
                        }
                    })
                    .overlay {
                        PlayerControls()
                    }
            }.onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showPlayerControls.toggle()
                }
                if isPlaying {
                    timeoutControls()
                }
            }.overlay(alignment: .bottom) {
                VideoSeekerView().offset(y: isRotated ? -15 : 0)
            }.overlay(alignment: .bottom) {
                BottomControls().offset(y: isRotated ? -15 : -0)
            }
        }.background {
            Rectangle().fill(.black)
        }
        .gesture(DragGesture().onEnded({ value in
            if -value.translation.height > 100 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRotated = true
                }
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRotated = false
                }
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }))
        .frame(width: videoPlayerSize.width)
        .frame(width: size.width)
        .offset(y: isRotated ? 10 : 0)
        .zIndex(10000)
        .onAppear {
            AppDelegate.orientationLock = .allButUpsideDown
            guard !isObserverAdded else {
                return
            }
            player.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main) { time in
                if let currentPlayerItem = player.currentItem {
                    let totalDuration = currentPlayerItem.duration.seconds
                    let currentDuration = player.currentTime().seconds
                    let calculatedProgress = currentDuration / totalDuration
                    if !isSeeking {
                        progress = calculatedProgress
                        lastDraggedValue = calculatedProgress
                    }
                    if calculatedProgress == 1 {
                        isFinishedPlaying = true
                    }
                    currentTime = currentDuration
                    duration = totalDuration.isNaN ? 0 : totalDuration
                }
            }
            isObserverAdded = true
            isPlaying.toggle()
        }.onDisappear {
            player.pause()
        }.navigationBarBackButtonHidden(isRotated)
    }
    
    @ViewBuilder
    func PlayerControls() -> some View {
        HStack (spacing: 25.0) {
            Button {
                seek(by: -10)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(15).background {
                        Circle()
                            .fill(Color.black.opacity(0.35))
                        
                    }
            }
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    if isFinishedPlaying {
                        isFinishedPlaying = false
                        player.seek(to: CMTime.zero)
                        progress = .zero
                        lastDraggedValue = .zero
                    }
                    if isPlaying {
                        if let timeoutTask {
                            timeoutTask.cancel()
                        }
                    } else {
                        timeoutControls()
                    }
                    isPlaying.toggle()
                }
            } label: {
                Image(systemName: isFinishedPlaying ? "arrow.clockwise" : (isPlaying ? "pause.fill" : "play.fill"))
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(15).background {
                        Circle()
                            .fill(Color.black.opacity(0.35))
                        
                    }.scaleEffect(1.1)
            }
            Button {
                seek(by: 10)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(15).background {
                        Circle()
                            .fill(Color.black.opacity(0.35))
                        
                    }
            }

        }.opacity(showPlayerControls && !isDragging ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDragging)
    }
    
    @ViewBuilder
    func BottomControls() -> some View {
        HStack {
            Text("\(currentTime.asString(style: .positional))/\(duration.asString(style: .positional))")
                    .foregroundColor(.white)
                    .font(.system(size: 12)).fontWeight(.semibold)
                    .padding(.horizontal, 10)
            
            Spacer()
            Button {
                if isRotated {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRotated = false
                    }
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRotated = true
                    }
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
            } label: {
                Image(systemName: isRotated ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right").resizable().frame(width: 15, height: 15).foregroundColor(.white)
            }.padding(.trailing, 8)
                .frame(width: 50, height: 50)
                .contentShape(Rectangle())
        }.opacity(showPlayerControls ? 1 : isSeeking ? 1 : 0).animation(.easeInOut(duration: 0.2), value: showPlayerControls)
            .padding(EdgeInsets(top: 0, leading: isRotated ? 40 : 0, bottom: 0, trailing: isRotated ? 40 : 0))
    }
    
    @ViewBuilder
    func VideoSeekerView( ) -> some View {
        ZStack (alignment: .leading) {
            Rectangle()
                .fill(Color.gray).frame(width: (isRotated ? size.height : size.width))
            
            Rectangle()
                .fill(Color.cyan).frame(width: max((progress.isNaN ? 0 : progress)*(isRotated ? size.height : size.width), 0))
            
        }.frame(height: 3)
            .overlay (alignment: .leading) {
                Circle().fill(.cyan)
                    .frame(width: 15, height: 15)
                    .scaleEffect(showPlayerControls || isDragging ? 1 : 0.001, anchor: .center)
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle())
                    .offset(x: progress*((isRotated ? size.height : size.width)-15))
                    .gesture(
                        DragGesture().updating($isDragging, body: { _, out, _ in
                            out = true
                        }).onChanged({ value in
                            if let timeoutTask {
                                timeoutTask.cancel()
                            }
                            
                            let transitionX = value.translation.width
                            let newProgress = (transitionX / ((isRotated ? size.height : size.width)-15)) + lastDraggedValue
                            
                            progress = max(min(newProgress, 1),0)
                            if let currentPlayerItem = player.currentItem {
                                let totalDuration = currentPlayerItem.duration.seconds
                                currentTime = progress*totalDuration
                            }
                            isSeeking = true
                            
                        }).onEnded({ value in
                            lastDraggedValue = progress
                            if let currentPlayerItem = player.currentItem {
                                let totalDuration = currentPlayerItem.duration.seconds
                                currentTime = progress*totalDuration
                                player.seek(to: .init(seconds: totalDuration*progress, preferredTimescale: 1))
                                if isPlaying {
                                    timeoutControls()
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                                    isSeeking = false
                                })
                            }
                        })
                    )
                    .frame(width: 15, height: 15)
            }.padding(EdgeInsets(top: 0, leading: isRotated ? 40 : 0, bottom: 0, trailing: isRotated ? 40 : 0))
    }
    
    func seek(by seconds: Double) {
        if let currentPlayerItem = player.currentItem {
            let totalDuration = currentPlayerItem.duration.seconds
            let currentDuration = player.currentTime().seconds
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
            player.seek(to: .init(seconds: newTime, preferredTimescale: 1))
            if isPlaying {
                timeoutControls()
            }
        }
    }
    
    func timeoutControls() {
        if let timeoutTask {
            timeoutTask.cancel()
        }
        timeoutTask = .init(block: {
            withAnimation(.easeOut(duration: 0.35)) {
                showPlayerControls = false
            }
        })
        if let timeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutTask)
        }
    }
}
