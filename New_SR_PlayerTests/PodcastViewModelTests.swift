//
//  PodcastViewModelTests.swift
//  New_SR_PlayerTests
//
//  Created by Alvar Arias on 2026-05-09.
//

import XCTest
@testable import New_SR_Player


// MARK: - MockSRAPIClient

final class MockSRAPIClient: SRAPIClientProtocol, @unchecked Sendable {
    var programsToReturn: [SRProgram] = []
    var podFilesToReturn: [SRPodFile] = []
    var shouldThrow = false

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


@MainActor
final class PodcastViewModelTests: XCTestCase {

    var vm: PodcastViewModel!
    var mockClient: MockSRAPIClient!

    let prog1 = SRProgram(id: 4923, name: "Ekot", description: "Nyheter", programimage: nil, programcategory: nil, channel: nil)
    let prog2 = SRProgram(id: 2071, name: "Sommar i P1", description: "Sommarprogram", programimage: nil, programcategory: nil, channel: nil)

    override func setUp() {
        super.setUp()
        mockClient = MockSRAPIClient()
        vm = PodcastViewModel(apiClient: mockClient)
    }

    override func tearDown() {
        vm = nil
        mockClient = nil
        super.tearDown()
    }


    // MARK: - load()

    func testLoad_populatesPrograms() async {
        mockClient.programsToReturn = [prog1, prog2]
        await vm.load()
        XCTAssertEqual(vm.programs.count, 2)
        XCTAssertEqual(vm.programs.first?.name, "Ekot")
    }

    func testLoad_setsIsLoadingFalseWhenDone() async {
        mockClient.programsToReturn = [prog1]
        await vm.load()
        XCTAssertFalse(vm.isLoading)
    }

    func testLoad_networkError_programsRemainEmpty() async {
        mockClient.shouldThrow = true
        await vm.load()
        XCTAssertTrue(vm.programs.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testLoad_networkError_showsBanner() async {
        let banner = BannerStore()
        vm.banner = banner
        mockClient.shouldThrow = true
        await vm.load()
        XCTAssertTrue(banner.isVisible)
        XCTAssertFalse(banner.message.isEmpty)
    }


    // MARK: - featured (carousel)

    func testFeatured_hasAtMostFivePrograms() async {
        mockClient.programsToReturn = (1...10).map {
            SRProgram(id: $0, name: "Prog \($0)", description: nil, programimage: nil, programcategory: nil, channel: nil)
        }
        await vm.load()
        XCTAssertLessThanOrEqual(vm.featured.count, 5)
    }

    func testFeatured_hasFivePrograms_whenEnoughExist() async {
        mockClient.programsToReturn = (1...10).map {
            SRProgram(id: $0, name: "Prog \($0)", description: nil, programimage: nil, programcategory: nil, channel: nil)
        }
        await vm.load()
        XCTAssertEqual(vm.featured.count, 5)
    }

    func testFeatured_isSubsetOfPrograms() async {
        mockClient.programsToReturn = (1...8).map {
            SRProgram(id: $0, name: "Prog \($0)", description: nil, programimage: nil, programcategory: nil, channel: nil)
        }
        await vm.load()
        let programIDs = Set(vm.programs.map(\.id))
        XCTAssertTrue(vm.featured.allSatisfy { programIDs.contains($0.id) })
    }

    func testFeatured_containsAllPrograms_whenFewerThanFive() async {
        mockClient.programsToReturn = [prog1, prog2]
        await vm.load()
        XCTAssertEqual(vm.featured.count, 2)
    }

    func testFeatured_isEmpty_whenLoadFails() async {
        mockClient.shouldThrow = true
        await vm.load()
        XCTAssertTrue(vm.featured.isEmpty)
    }


    // MARK: - PodFileListViewModel

    func testPodFileListLoad_populatesPodFiles() async {
        mockClient.podFilesToReturn = [makePodFile(id: 1, title: "Avsnitt 1")]
        let podVm = PodFileListViewModel(apiClient: mockClient)
        await podVm.load(programID: 4923)
        XCTAssertEqual(podVm.podFiles.count, 1)
        XCTAssertEqual(podVm.podFiles.first?.title, "Avsnitt 1")
    }

    func testPodFileListLoad_setsIsLoadingFalseWhenDone() async {
        let podVm = PodFileListViewModel(apiClient: mockClient)
        await podVm.load(programID: 4923)
        XCTAssertFalse(podVm.isLoading)
    }

    func testPodFileListLoad_networkError_showsBanner() async {
        let banner = BannerStore()
        mockClient.shouldThrow = true
        let podVm = PodFileListViewModel(apiClient: mockClient)
        podVm.banner = banner
        await podVm.load(programID: 4923)
        XCTAssertTrue(banner.isVisible)
        XCTAssertFalse(banner.message.isEmpty)
    }


    // MARK: - Helpers

    private func makePodFile(id: Int, title: String) -> SRPodFile {
        SRPodFile(id: id, title: title, description: nil, duration: 1800, url: nil, publishdateutc: nil)
    }
}
