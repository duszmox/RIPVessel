import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
        
    @Binding var play: Bool
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @Binding var isBuffering: Bool
    
    var player: AVPlayer

    @Binding var progress: CGFloat

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

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        let player = uiViewController.player

        // Check if the AVPlayerItem has changed
        if let currentItem = player?.currentItem {
            if currentItem != context.coordinator.observedItem {
                // Remove observers from the old item
                context.coordinator.removeObservers()
                // Add observers to the new item
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
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var observedItem: AVPlayerItem?

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
