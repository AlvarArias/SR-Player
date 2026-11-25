//
//  HomeViewModel.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-11.
//

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
    @Published var discoverPrograms: [SRProgram] = []
    @Published var discoverFailed = false

    var banner: BannerStore?
    private let apiClient: any SRAPIClientProtocol
    private let audioPlayer: any AudioPlayerProtocol

    static let discoverCount = 3

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
        } catch {
            banner?.show("Ingen anslutning — kontrollera nätverket")
        }
        await refreshDiscover()
    }

    /// Fetches podcasts and picks `discoverCount` random ones.
    /// The pick is stored, so it stays stable across SwiftUI redraws and only
    /// changes when this is called again (app launch or pull-to-refresh).
    func refreshDiscover() async {
        do {
            let programs = try await apiClient.fetchPrograms()
            discoverPrograms = Self.pickRandom(from: Self.eligibleForDiscover(programs), count: Self.discoverCount)
            discoverFailed = false
        } catch {
            discoverFailed = discoverPrograms.isEmpty
        }
    }

    static func eligibleForDiscover(_ programs: [SRProgram]) -> [SRProgram] {
        programs.filter { program in
            !PodcastViewModel.excludedPrefixes.contains(where: { program.name.hasPrefix($0) })
        }
    }

    /// Up to `count` distinct programs, in random order.
    static func pickRandom(from programs: [SRProgram], count: Int) -> [SRProgram] {
        var seen = Set<Int>()
        let unique = programs.filter { seen.insert($0.id).inserted }
        return Array(unique.shuffled().prefix(count))
    }

    func togglePlay(id: Int) {
        guard let channel = channels.first(where: { $0.id == id }) else { return }
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
}
