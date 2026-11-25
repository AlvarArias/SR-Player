//
//  HomeViewModelTests.swift
//  New_SR_PlayerTests
//
//  Created by Alvar Arias on 2026-05-06.
//

import XCTest
@testable import New_SR_Player


// MARK: - MockSRAPIClient

final class MockSRAPIClient: SRAPIClientProtocol, @unchecked Sendable {
    var channelsToReturn: [SRChannel] = []
    var nowPlayingToReturn: SRScheduleEpisode? = nil
    var nowPlayingSongToReturn: SRSong? = nil
    var programsToReturn: [SRProgram] = []
    var podFilesToReturn: [SRPodFile] = []
    var shouldThrow = false

    func fetchChannels() async throws -> [SRChannel] {
        if shouldThrow { throw MockAPIError.network }
        return channelsToReturn
    }

    func fetchNowPlaying(channelID: Int) async throws -> SRScheduleEpisode? {
        if shouldThrow { throw MockAPIError.network }
        return nowPlayingToReturn
    }

    func fetchNowPlayingSong(channelID: Int) async throws -> SRSong? {
        if shouldThrow { throw MockAPIError.network }
        return nowPlayingSongToReturn
    }

    func fetchPrograms() async throws -> [SRProgram] {
        if shouldThrow { throw MockAPIError.network }
        return programsToReturn
    }

    func fetchPodFiles(programID: Int) async throws -> [SRPodFile] {
        if shouldThrow { throw MockAPIError.network }
        return podFilesToReturn
    }

    enum MockAPIError: Error { case network }
}


// MARK: - MockAudioPlayer

final class MockAudioPlayer: AudioPlayerProtocol {
    private(set) var playingChannelID: Int? = nil
    private(set) var toggleCallCount = 0
    var onBufferingChange: (@Sendable (Bool) -> Void)? = nil

    func toggle(channel: SRChannel) {
        toggleCallCount += 1
        if playingChannelID == channel.id {
            playingChannelID = nil
        } else {
            playingChannelID = channel.id
        }
    }

    func stop() {
        playingChannelID = nil
    }
}


// MARK: - HomeViewModelTests

@MainActor
final class HomeViewModelTests: XCTestCase {

    var vm: HomeViewModel!
    var mockClient: MockSRAPIClient!
    var mockPlayer: MockAudioPlayer!

    let p1 = SRChannel(id: 132, name: "P1", tagline: "Nyheter och kultur", color: "31a1d5", image: nil, liveaudio: nil)
    let p3 = SRChannel(id: 164, name: "P3", tagline: "Unga vuxna", color: "ff5a00", image: nil, liveaudio: nil)

    override func setUp() {
        super.setUp()
        mockClient = MockSRAPIClient()
        mockPlayer = MockAudioPlayer()
        vm = HomeViewModel(apiClient: mockClient, audioPlayer: mockPlayer)
    }

    override func tearDown() {
        vm = nil
        mockClient = nil
        mockPlayer = nil
        super.tearDown()
    }


    // MARK: - load()

    func testLoad_populatesChannels() async {
        mockClient.channelsToReturn = [p1, p3]
        await vm.load()
        XCTAssertEqual(vm.channels.count, 2)
        XCTAssertEqual(vm.channels.first?.id, 132)
    }

    func testLoad_setsIsLoadingFalseWhenDone() async {
        mockClient.channelsToReturn = [p1]
        await vm.load()
        XCTAssertFalse(vm.isLoading)
    }

    func testLoad_populatesNowPlaying() async {
        let episode = makeEpisode(title: "Ekot")
        mockClient.channelsToReturn = [p1]
        mockClient.nowPlayingToReturn = episode
        await vm.load()
        XCTAssertEqual(vm.nowPlaying[132]?.title, "Ekot")
    }

    func testLoad_networkError_channelsRemainEmpty() async {
        mockClient.shouldThrow = true
        await vm.load()
        XCTAssertTrue(vm.channels.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoad_networkError_showsBanner() async {
        let banner = BannerStore()
        vm.banner = banner
        mockClient.shouldThrow = true
        await vm.load()
        XCTAssertTrue(banner.isVisible)
        XCTAssertFalse(banner.message.isEmpty)
    }


    // MARK: - togglePlay()

    func testTogglePlay_setsPlayingChannelID() {
        vm.channels = [p1]
        vm.togglePlay(id: 132)
        XCTAssertEqual(vm.playingChannelID, 132)
    }

    func testTogglePlay_sameID_stopsPlayback() {
        vm.channels = [p1]
        vm.togglePlay(id: 132)
        vm.togglePlay(id: 132)
        XCTAssertNil(vm.playingChannelID)
    }

    func testTogglePlay_unknownID_doesNothing() {
        vm.channels = [p1]
        vm.togglePlay(id: 999)
        XCTAssertNil(vm.playingChannelID)
        XCTAssertEqual(mockPlayer.toggleCallCount, 0)
    }


    // MARK: - tagline()

    func testTagline_usesNowPlayingTitle() {
        vm.nowPlaying[132] = makeEpisode(title: "Aktuellt")
        XCTAssertEqual(vm.tagline(for: p1), "Aktuellt")
    }

    func testTagline_fallsBackToChannelTagline() {
        XCTAssertEqual(vm.tagline(for: p1), "Nyheter och kultur")
    }


    // MARK: - Discover podcasts

    func testDiscover_picksExactlyThreeDistinctPrograms() async {
        mockClient.programsToReturn = (1...20).map { makeProgram(id: $0) }
        await vm.load()
        XCTAssertEqual(vm.discoverPrograms.count, 3)
        XCTAssertEqual(Set(vm.discoverPrograms.map(\.id)).count, 3)
    }

    func testDiscover_fewerThanThree_showsWhatExists() async {
        mockClient.programsToReturn = [makeProgram(id: 1), makeProgram(id: 2)]
        await vm.load()
        XCTAssertEqual(vm.discoverPrograms.count, 2)
    }

    func testDiscover_removesDuplicateIDs() async {
        mockClient.programsToReturn = [makeProgram(id: 1), makeProgram(id: 1), makeProgram(id: 1)]
        await vm.load()
        XCTAssertEqual(vm.discoverPrograms.map(\.id), [1])
    }

    func testDiscover_excludesLiveChannelShows() async {
        mockClient.programsToReturn = [makeProgram(id: 1, name: "Morgon i P3"), makeProgram(id: 2, name: "Sommar i P1")]
        await vm.load()
        XCTAssertEqual(vm.discoverPrograms.map(\.id), [2])
    }

    func testDiscover_networkError_isEmptyAndFlagged() async {
        mockClient.shouldThrow = true
        await vm.load()
        XCTAssertTrue(vm.discoverPrograms.isEmpty)
        XCTAssertTrue(vm.discoverFailed)
    }

    func testDiscover_refreshFailure_keepsPreviousPick() async {
        mockClient.programsToReturn = (1...10).map { makeProgram(id: $0) }
        await vm.refreshDiscover()
        let before = vm.discoverPrograms.map(\.id)
        mockClient.shouldThrow = true
        await vm.refreshDiscover()
        XCTAssertEqual(vm.discoverPrograms.map(\.id), before)
        XCTAssertFalse(vm.discoverFailed)
    }


    // MARK: - Helpers

    private func makeProgram(id: Int, name: String? = nil) -> SRProgram {
        SRProgram(id: id, name: name ?? "Prog \(id)", description: nil, programimage: nil, programcategory: nil, channel: nil)
    }

    private func makeEpisode(title: String) -> SRScheduleEpisode {
        SRScheduleEpisode(
            title: title,
            description: nil,
            starttimeutc: MicrosoftDate(date: Date().addingTimeInterval(-60)),
            endtimeutc: MicrosoftDate(date: Date().addingTimeInterval(60)),
            imageurl: nil
        )
    }
}
