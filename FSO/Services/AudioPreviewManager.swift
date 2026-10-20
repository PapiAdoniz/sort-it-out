import AVFoundation
import Observation

@Observable
final class AudioPreviewManager {
    private var player: AVPlayer?
    var isPlaying = false
    var currentPreviewURL: URL?
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playlist: [URL] = []
    var currentIndex: Int = 0

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    func playPreview(url: URL) {
        if currentPreviewURL == url && isPlaying {
            pausePreview()
            return
        }

        stopPreview()
        currentPreviewURL = url

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }

        Task {
            let duration = try? await asset.load(.duration)
            await MainActor.run {
                self.duration = duration?.seconds ?? 0
            }
        }

        player.play()
        isPlaying = true
    }

    func pausePreview() {
        player?.pause()
        isPlaying = false
    }

    func resumePreview() {
        player?.play()
        isPlaying = true
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
        currentTime = time
    }

    func stopPreview() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        currentPreviewURL = nil
        currentTime = 0
        duration = 0
    }

    func setPlaylist(_ urls: [URL], startIndex: Int = 0) {
        playlist = urls
        currentIndex = startIndex
    }

    func playNext() {
        guard currentIndex < playlist.count - 1 else { return }
        currentIndex += 1
        playPreview(url: playlist[currentIndex])
    }

    func playPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        playPreview(url: playlist[currentIndex])
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        player?.pause()
        player = nil
    }
}
