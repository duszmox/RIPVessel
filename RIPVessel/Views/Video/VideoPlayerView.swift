import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    @Binding var play: Bool
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @Binding var isBuffering: Bool
    var player: AVPlayer
    @Binding var progress: CGFloat
    let initialProgress: Int?

    // Add a token for the time observer
    @State private var timeObserverToken: Any?
    var observeProgress: (Double) -> Void
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.updatesNowPlayingInfoCenter = true
        controller.showsPlaybackControls = false

        if let currentItem = player.currentItem {
            context.coordinator.addObservers(to: currentItem)
        }
        if let initialProgress {
            player.seek(to: CMTime(seconds: CGFloat(initialProgress), preferredTimescale: 1))
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }

        let interval = CMTimeMakeWithSeconds(15, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
            reportProgress()
            
        }
        
        context.coordinator.timeObserverToken = token

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        let player = uiViewController.player

        if let currentItem = player?.currentItem {
            if currentItem != context.coordinator.observedItem {
                context.coordinator.removeObservers()
                context.coordinator.addObservers(to: currentItem)
            }
        }

        if play {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.removeObservers()
        
        if let player = uiViewController.player, let token = coordinator.timeObserverToken {
            player.removeTimeObserver(token)
        }
        
        coordinator.parent.reportProgress()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func reportProgress() {
        guard let currentTime = player.currentItem?.currentTime(),
              let duration = player.currentItem?.duration,
              duration.isNumeric && duration.seconds > 0 else {
            return
        }
        let progress = currentTime.seconds
        observeProgress(progress)
    }

    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var observedItem: AVPlayerItem?
        var timeObserverToken: Any?

        init(_ parent: VideoPlayerView) {
            self.parent = parent
        }

        func addObservers(to item: AVPlayerItem) {
            item.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
            item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.old, .new], context: nil)
            item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.old, .new], context: nil)
            observedItem = item
        }

        func removeObservers() {
            if let item = observedItem {
                item.removeObserver(self, forKeyPath: "status")
                item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
                item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
                observedItem = nil
            }
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey : Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard let item = object as? AVPlayerItem else { return }

            if keyPath == "status" {
                if item.status == .failed {
                    print("Failed to load video")
                }
            } else if keyPath == "playbackBufferEmpty" {
                DispatchQueue.main.async {
                    self.parent.isBuffering = item.isPlaybackBufferEmpty
                }
            } else if keyPath == "playbackLikelyToKeepUp" {
                DispatchQueue.main.async {
                    self.parent.isBuffering = !item.isPlaybackLikelyToKeepUp
                }
            }
        }
    }
}
