//
//  FavoritesStoreTests.swift
//  New_SR_PlayerTests
//
//  Created by Alvar Arias on 2026-05-09.
//

import XCTest
@testable import New_SR_Player


final class FavoritesStoreTests: XCTestCase {

    var store: FavoritesStore!
    private let key = "favoritePodFiles"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
        store = FavoritesStore()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        store = nil
        super.tearDown()
    }

    private func makePodFile(id: Int, title: String = "Avsnitt") -> SRPodFile {
        SRPodFile(id: id, title: title, description: nil, duration: 1800, url: nil, publishdateutc: nil)
    }


    // MARK: - toggle()

    func testToggle_addsEpisode() {
        store.toggle(episode: makePodFile(id: 1))
        XCTAssertEqual(store.favorites.count, 1)
        XCTAssertEqual(store.favorites.first?.id, 1)
    }

    func testToggle_removesEpisode() {
        let ep = makePodFile(id: 1)
        store.toggle(episode: ep)
        store.toggle(episode: ep)
        XCTAssertTrue(store.favorites.isEmpty)
    }


    // MARK: - isFavorite()

    func testIsFavorite_returnsTrueAfterToggle() {
        store.toggle(episode: makePodFile(id: 42))
        XCTAssertTrue(store.isFavorite(id: 42))
    }

    func testIsFavorite_returnsFalseAfterDoubleToggle() {
        let ep = makePodFile(id: 42)
        store.toggle(episode: ep)
        store.toggle(episode: ep)
        XCTAssertFalse(store.isFavorite(id: 42))
    }

    func testIsFavorite_returnsFalseForUnknownID() {
        XCTAssertFalse(store.isFavorite(id: 999))
    }


    // MARK: - Persistence

    func testPersistence_survivesNewInstance() {
        store.toggle(episode: makePodFile(id: 7, title: "Cached Avsnitt"))
        let newStore = FavoritesStore()
        XCTAssertEqual(newStore.favorites.count, 1)
        XCTAssertEqual(newStore.favorites.first?.title, "Cached Avsnitt")
    }
}
