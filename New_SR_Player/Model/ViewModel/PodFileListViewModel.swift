//
//  PodFileListViewModel.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-11.
//

import AVFoundation
import FirebaseAnalytics
import SwiftUI


@MainActor
final class PodFileListViewModel: ObservableObject {
    @Published var podFiles: [SRPodFile] = []
    @Published var isLoading = false
    @Published var playingID: Int?

    var banner: BannerStore?
    private let apiClient: any SRAPIClientProtocol
    private var player: AVPlayer?

    init(apiClient: any SRAPIClientProtocol = SRAPIClient()) {
        self.apiClient = apiClient
    }

    func load(programID: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            podFiles = try await apiClient.fetchPodFiles(programID: programID)
        } catch {
            banner?.show("Kunde inte ladda avsnitt — kontrollera nätverket")
        }
    }

    func toggle(podFile: SRPodFile) {
        guard let urlString = podFile.url, let url = URL(string: urlString) else { return }
        if playingID == podFile.id {
            player?.pause()
            player = nil
            playingID = nil
            Analytics.logPodcastPlay(episodeID: podFile.id, episodeTitle: podFile.title, action: "pause")
        } else {
            configureSession()
            player?.pause()
            player = AVPlayer(url: url)
            player?.play()
            playingID = podFile.id
            Analytics.logPodcastPlay(episodeID: podFile.id, episodeTitle: podFile.title, action: "play")
        }
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    func stop() {
        player?.pause()
        player = nil
        playingID = nil
    }
}
