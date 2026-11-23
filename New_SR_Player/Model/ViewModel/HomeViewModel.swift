//
//  HomeViewModel.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-11.
//

import AVFoundation
import FirebaseAnalytics
import SwiftUI


@MainActor
final class HomeViewModel: ObservableObject {
    @Published var channels: [SRChannel] = []
    @Published var nowPlaying: [Int: SRScheduleEpisode] = [:]
    @Published var nowPlayingSong: [Int: SRSong] = [:]
    @Published var isLoading = false
    @Published var playingChannelID: Int?
    @Published var bufferingChannelID: Int?
    @Published var vaderEpisode: SRPodFile?
    @Published var vaderIsPlaying = false

    var banner: BannerStore?
    private let apiClient: any SRAPIClientProtocol
    private let audioPlayer: any AudioPlayerProtocol
    private var vaderPlayer: AVPlayer?

    private static let vaderProgramID = 2000

    init(
        apiClient: any SRAPIClientProtocol = SRAPIClient(),
        audioPlayer: any AudioPlayerProtocol = AudioPlayer()
    ) {
        self.apiClient = apiClient
        self.audioPlayer = audioPlayer
        audioPlayer.onBufferingChange = { [weak self] isBuffering in
            Task { @MainActor [weak self] in
                self?.bufferingChannelID = isBuffering ? self?.audioPlayer.playingChannelID : nil
            }
        }
    }

    var featured: SRChannel? { channels.first }
    var listed: [SRChannel] { Array(channels.dropFirst()) }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            channels = try await apiClient.fetchChannels()
            for channel in channels {
                if let ep = try? await apiClient.fetchNowPlaying(channelID: channel.id) {
                    nowPlaying[channel.id] = ep
                }
                if let song = try? await apiClient.fetchNowPlayingSong(channelID: channel.id) {
                    nowPlayingSong[channel.id] = song
                }
            }
            vaderEpisode = try? await apiClient.fetchPodFiles(programID: Self.vaderProgramID).first
        } catch {
            banner?.show("Ingen anslutning — kontrollera nätverket")
        }
    }

    func togglePlay(id: Int) {
        guard let channel = channels.first(where: { $0.id == id }) else { return }
        if vaderIsPlaying {
            vaderPlayer?.pause()
            vaderPlayer = nil
            vaderIsPlaying = false
        }
        audioPlayer.toggle(channel: channel)
        playingChannelID = audioPlayer.playingChannelID
        let action = audioPlayer.playingChannelID == id ? "play" : "pause"
        Analytics.logRadioPlay(channelID: id, channelName: channel.name, action: action)
    }

    func tagline(for channel: SRChannel) -> String {
        nowPlaying[channel.id]?.title ?? channel.tagline
    }

    func currentSong(for channel: SRChannel) -> SRSong? {
        nowPlayingSong[channel.id]
    }

    func toggleVader() {
        guard let episode = vaderEpisode,
              let urlString = episode.url,
              let url = URL(string: urlString) else { return }
        if vaderIsPlaying {
            vaderPlayer?.pause()
            vaderPlayer = nil
            vaderIsPlaying = false
        } else {
            audioPlayer.stop()
            playingChannelID = nil
            vaderPlayer = AVPlayer(url: url)
            vaderPlayer?.play()
            vaderIsPlaying = true
        }
    }
}
