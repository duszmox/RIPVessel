//
//  VideoView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 28..
//


import SwiftUI
import AVKit

import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    
    let controller = AVPlayerViewController()
    
    @Binding var play: Bool
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @Binding var isBuffering: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = createPlayer()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        controller.updatesNowPlayingInfoCenter = true
        controller.showsPlaybackControls = true

        addObservers(to: player.currentItem!, context: context)

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        let player = controller.player
        
        print(player?.currentItem)
        if let currentItem = player?.currentItem,
           currentItem.asset as? AVURLAsset != AVURLAsset(url: URL(string: url.absoluteString + (currentQuality?.url ?? ""))!) {
            let newPlayer = createPlayer()
            controller.player = newPlayer
            addObservers(to: newPlayer.currentItem!, context: context)
            if play {
                newPlayer.play()
            }
        } else {
            if play {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }
    
    private func createPlayer() -> AVPlayer {
        let asset = AVURLAsset(url: URL(string: url.absoluteString + (currentQuality?.url ?? ""))!)
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        return player
    }
    
    private func addObservers(to item: AVPlayerItem, context: Context) {
        item.addObserver(context.coordinator, forKeyPath: "status", options: [.old, .new], context: nil)
        item.addObserver(context.coordinator, forKeyPath: "playbackBufferEmpty", options: [.old, .new], context: nil)
        item.addObserver(context.coordinator, forKeyPath: "playbackLikelyToKeepUp", options: [.old, .new], context: nil)
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        if let currentItem = uiViewController.player?.currentItem {
            currentItem.removeObserver(coordinator, forKeyPath: "status")
            currentItem.removeObserver(coordinator, forKeyPath: "playbackBufferEmpty")
            currentItem.removeObserver(coordinator, forKeyPath: "playbackLikelyToKeepUp")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: VideoPlayerView

        init(_ parent: VideoPlayerView) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let item = object as? AVPlayerItem else { return }
            
            if keyPath == "status" {
                if item.status == .failed {
                    print("Failed to load video")
                }
            } else if keyPath == "playbackBufferEmpty" {
                if item.isPlaybackBufferEmpty {
                    DispatchQueue.main.async {
                        self.parent.isBuffering = true
                    }
                }
            } else if keyPath == "playbackLikelyToKeepUp" {
                if item.isPlaybackLikelyToKeepUp {
                    DispatchQueue.main.async {
                        self.parent.isBuffering = false
                    }
                }
            }
        }
    }
}



struct VideoView: View {
    @StateObject private var vm: ViewModel
    @State private var isPlaying = false
    @State private var isBuffering = false
    
    init(post: Components.Schemas.BlogPostModelV3) {
        _vm = StateObject(wrappedValue: ViewModel(post: post))
    }
    
    var body: some View {
        VStack {
            if let stream = vm.stream {
                ZStack {
                    VideoPlayerView(url: URL(string: stream.groups.first?.origins?.first?.url ?? "")!, play: $isPlaying, currentQuality: $vm.currentQuality, isBuffering: $isBuffering)
                        .aspectRatio(16/9, contentMode: .fit)
                        .onAppear {
                            isPlaying = true
                        }
                    
                    if isBuffering {
                        ProgressView("Buffering...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
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
        }
        .onAppear {
            print("VideoView")
        }
        .navigationBarBackButtonHidden(false)
    }
}


//#Preview {
//    VideoView()
//}
