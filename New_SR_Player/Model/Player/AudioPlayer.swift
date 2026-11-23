//
//  AudioPlayer.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-06.
//

import AVFoundation
import Foundation
import MediaPlayer
import UIKit


// MARK: - Protocol (testability)

protocol AudioPlayerProtocol: AnyObject {
    var playingChannelID: Int? { get }
    var onBufferingChange: (@Sendable (Bool) -> Void)? { get set }
    func toggle(channel: SRChannel)
    func stop()
}


final class AudioPlayer: AudioPlayerProtocol {

    private var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?
    private(set) var playingChannelID: Int?
    var onBufferingChange: (@Sendable (Bool) -> Void)?
    private var currentChannel: SRChannel?

    init() {
        setupRemoteCommands()
    }

    func toggle(channel: SRChannel) {
        if playingChannelID == channel.id {
            stop()
        } else {
            play(channel: channel)
        }
    }

    func stop() {
        statusObserver = nil
        player?.pause()
        player = nil
        playingChannelID = nil
        currentChannel = nil
        onBufferingChange?(false)
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }


    // MARK: - Private

    private func play(channel: SRChannel) {
        guard
            let urlString = channel.liveaudio?.url,
            let url = URL(string: urlString)
        else { return }

        configureSession()
        statusObserver = nil
        player?.pause()
        player = AVPlayer(url: url)
        statusObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let buffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            self?.onBufferingChange?(buffering)
        }
        player?.play()
        playingChannelID = channel.id
        currentChannel = channel
        updateNowPlaying(channel: channel)
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            guard let self, let channel = self.currentChannel else { return .noSuchContent }
            self.play(channel: channel)
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self, let channel = self.currentChannel else { return .noSuchContent }
            self.toggle(channel: channel)
            return .success
        }
    }

    private func updateNowPlaying(channel: SRChannel) {
        MPNowPlayingInfoCenter.default().playbackState = .playing
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: channel.name,
            MPMediaItemPropertyArtist: "Sveriges Radio",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]
        guard let urlString = channel.image, let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let uiImage = UIImage(data: data) else { return }
            let artwork = MPMediaItemArtwork(boundsSize: uiImage.size) { _ in uiImage }
            var updated = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            updated[MPMediaItemPropertyArtwork] = artwork
            DispatchQueue.main.async {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
            }
        }.resume()
    }
}
