import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
        
    @Binding var play: Bool
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @Binding var isBuffering: Bool
    
    @State var player: AVPlayer?
    @Binding var progress: CGFloat

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        if let player {
            controller.player = player
            controller.allowsPictureInPicturePlayback = true
            controller.canStartPictureInPictureAutomaticallyFromInline = true
            controller.updatesNowPlayingInfoCenter = true
            controller.showsPlaybackControls = false

            addObservers(to: controller.player!.currentItem!, context: context)
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
        
        if let currentItem = player?.currentItem,
           (currentItem.asset as? AVURLAsset)?.url != URL(string: url.absoluteString + (currentQuality?.url ?? "")) {
            player?.pause()
            currentItem.removeObserver(context.coordinator, forKeyPath: "status")
            currentItem.removeObserver(context.coordinator, forKeyPath: "playbackBufferEmpty")
            currentItem.removeObserver(context.coordinator, forKeyPath: "playbackLikelyToKeepUp")
            uiViewController.player?.replaceCurrentItem(with: self.createAVItem())
            addObservers(to: player!.currentItem!, context: context)
            player?.currentItem?.seek(to: .init(seconds: currentItem.duration.seconds*progress, preferredTimescale: 1), completionHandler: { _ in
                if play {
                    player?.play()
                }
            })
        } else {
            if play {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }
    
    private func createAVItem() -> AVPlayerItem {
        let asset = AVURLAsset(url: URL(string: url.absoluteString + (currentQuality?.url ?? ""))!, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true, AVURLAssetHTTPCookiesKey: HTTPCookieStorage.shared.cookies as Any])
        let item = AVPlayerItem(asset: asset)
        return item
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
