//
//  SplashScreenView.swift
//  OwlLala
//
//  Created by Amanda on 14/07/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct SplashScreenView: View {

    /// Called automatically after the splash video finishes or when fallback timing is reached.
    var onFinished: () -> Void = {}

    @State private var player: AVPlayer?
    @State private var didFinish = false
    @State private var playbackObserver: NSObjectProtocol?

    private let fallbackDuration: UInt64 = 4_000_000_000

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if let player {
                SplashVideoPlayer(player: player)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
        }
        .task {
            await startSplashVideo()
        }
        .onDisappear {
            stopSplashVideo()
        }
    }

    @MainActor
    private func startSplashVideo() async {
        guard player == nil, !didFinish else {
            return
        }

        guard let videoURL = makeSplashVideoURL() else {
            finishIfNeeded()
            return
        }

        let avPlayer = AVPlayer(url: videoURL)
        avPlayer.actionAtItemEnd = .pause
        player = avPlayer

        playbackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                finishIfNeeded()
            }
        }

        avPlayer.play()

        try? await Task.sleep(nanoseconds: fallbackDuration)
        finishIfNeeded()
    }

    private func makeSplashVideoURL() -> URL? {
        guard let dataAsset = NSDataAsset(name: "splashScreenVid") else {
            return nil
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("splashScreenVid")
            .appendingPathExtension("mp4")

        do {
            try dataAsset.data.write(to: fileURL, options: [.atomic])
            return fileURL
        } catch {
            return nil
        }
    }

    @MainActor
    private func finishIfNeeded() {
        guard !didFinish else {
            return
        }

        didFinish = true
        stopSplashVideo()
        onFinished()
    }

    private func stopSplashVideo() {
        player?.pause()
        player = nil

        if let playbackObserver {
            NotificationCenter.default.removeObserver(playbackObserver)
            self.playbackObserver = nil
        }
    }
}

private struct SplashVideoPlayer: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerView: UIView {

    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            return AVPlayerLayer()
        }

        return layer
    }
}

#Preview(traits: .landscapeRight) {
    let storageService = StorageService()

    return SplashScreenView()
        .environmentObject(storageService)
        .environmentObject(SettingsViewModel(storageService: storageService))
}
