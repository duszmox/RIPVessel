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
        let videoPlayerSize: CGSize = .init(width: isRotated ? size.height : size.width, height: isRotated ? size.width : (size.height/3.5))
        ZStack {
            VideoPlayerView(url: URL(string: videoURL)!, play: $isPlaying, currentQuality: $currentQuality, isBuffering: $isBuffering, player: player, progress: $progress).overlay {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .opacity(showPlayerControls || isDragging ? 1 : 0)
                    .animation(.easeInOut(duration: 0.35), value: isDragging)
                    .overlay {
                        PlayerControls()
                    }.overlay(content: {
                        HStack (spacing: 60) {
                            DoubleTapSeek {
                                let seconds = player.currentTime().seconds - 15
                                player.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
                            }
                            DoubleTapSeek(isForward: true) {
                                let seconds = player.currentTime().seconds + 15
                                player.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
                            }
                        }
                    })
            }.onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showPlayerControls.toggle()
                }
                if isPlaying {
                    timeoutControls()
                }
            }.overlay(alignment: .bottom) {
                VideoSeekerView().offset(y: isRotated ? -15 : 0)
            }
        }.background {
            Rectangle().fill(.black).padding(.trailing, isRotated ? -safeArea.bottom : 0)
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
        .frame(width: videoPlayerSize.width, height: videoPlayerSize.height)
        .frame(width: size.width, height: size.height/3.5)
        .offset(y: isRotated ? (size.width/3.5-(safeArea.bottom/2)) : 0)
//        .rotationEffect(.init(degrees: isRotated ? 90 : 0), anchor: .topLeading)
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
                if let currentPlayerItem = player.currentItem {
                    let totalDuration = currentPlayerItem.duration.seconds
                    let currentDuration = player.currentTime().seconds
                    var newTime = currentDuration - 10
                    if newTime < 0 {
                        newTime = 0
                    }
                    let newProgress = newTime / totalDuration
                    progress = newProgress
                    lastDraggedValue = newProgress
                    player.seek(to: .init(seconds: newTime, preferredTimescale: 1))
                    if isPlaying {
                        timeoutControls()
                    }
             }
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title)
//                    .fontWeight(.ultraLight)
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
        if let currentPlayerItem = player.currentItem {
            let totalDuration = currentPlayerItem.duration.seconds
            let currentDuration = player.currentTime().seconds
            var newTime = currentDuration + 10
            if newTime > totalDuration {
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
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title)
//                    .fontWeight(.ultraLight)
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
    func VideoSeekerView( ) -> some View {
        ZStack (alignment: .leading) {
            Rectangle()
                .fill(Color.gray)
            
            Rectangle()
                .fill(Color.cyan).frame(width: max((progress.isNaN ? 0 : progress)*size.width, 0))
                
        }.frame(height: 3)
            .overlay (alignment: .leading) {
            Circle().fill(.cyan)
                .frame(width: 15, height: 15)
                .scaleEffect(showPlayerControls || isDragging ? 1 : 0.001, anchor: progress*size.width > 15 ? .trailing : .leading)
                .frame(width: 50, height: 50)
                .contentShape(Rectangle())
                .offset(x: progress*size.width)
                .gesture(
                    DragGesture().updating($isDragging, body: { _, out, _ in
                        out = true
                    }).onChanged({ value in
                        if let timeoutTask {
                            timeoutTask.cancel()
                        }
                        
                        let transitionX = value.translation.width
                        let newProgress = (transitionX / size.width) + lastDraggedValue
                        
                        progress = max(min(newProgress, 1),0)
                        isSeeking = true
                        
                    }).onEnded({ value in
                        lastDraggedValue = progress
                        if let currentPlayerItem = player.currentItem {
                            let totalDuration = currentPlayerItem.duration.seconds
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
                .offset(x: progress*size.width > 15 ? -15 : 0)
                .frame(width: 15, height: 15)
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
