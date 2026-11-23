//
//  SRAPIClient.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-06.
//

import Foundation


// MARK: - Protocol (testability)

protocol SRAPIClientProtocol: Sendable {
    func fetchChannels() async throws -> [SRChannel]
    func fetchNowPlaying(channelID: Int) async throws -> SRScheduleEpisode?
    func fetchNowPlayingSong(channelID: Int) async throws -> SRSong?
    func fetchPrograms() async throws -> [SRProgram]
    func fetchPodFiles(programID: Int) async throws -> [SRPodFile]
}


struct SRAPIClient: SRAPIClientProtocol {

    static let trackedChannelIDs: Set<Int> = [132, 163, 164, 4951]

    private let base = "https://api.sr.se/api/v2"


    // MARK: - Channels

    func fetchChannels() async throws -> [SRChannel] {
        let url = URL(string: "\(base)/channels?format=json&size=100")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SRChannelsResponse.self, from: data)
        return response.channels
            .filter { Self.trackedChannelIDs.contains($0.id) }
    }


    // MARK: - Programs (podcasts)

    func fetchPrograms() async throws -> [SRProgram] {
        let url = URL(string: "\(base)/programs/index?format=json&haspod=true&size=100")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SRProgramsResponse.self, from: data)
        return response.programs
    }

    func fetchPodFiles(programID: Int) async throws -> [SRPodFile] {
        let url = URL(string: "\(base)/podfiles?programid=\(programID)&format=json&size=20")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SRPodFilesResponse.self, from: data)
        return response.podfiles
    }


    // MARK: - Now playing music

    func fetchNowPlayingSong(channelID: Int) async throws -> SRSong? {
        let url = URL(string: "\(base)/playlists/rightnow?channelid=\(channelID)&format=json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SRPlaylistResponse.self, from: data)
        return response.playlist.song
    }


    // MARK: - Now playing

    func fetchNowPlaying(channelID: Int) async throws -> SRScheduleEpisode? {
        let url = URL(string: "\(base)/scheduledepisodes?channelid=\(channelID)&format=json&size=100")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SRScheduleResponse.self, from: data)
        let now = Date()
        if let current = response.schedule.first(where: { $0.starttimeutc.date <= now && $0.endtimeutc.date >= now }) {
            return current
        }
        // Fallback: most recently started episode (gap between programs)
        return response.schedule.filter { $0.starttimeutc.date <= now }
            .max(by: { $0.starttimeutc.date < $1.starttimeutc.date })
    }
}
