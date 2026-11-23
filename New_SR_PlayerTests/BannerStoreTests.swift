//
//  BannerStoreTests.swift
//  New_SR_PlayerTests
//

import XCTest
@testable import New_SR_Player


@MainActor
final class BannerStoreTests: XCTestCase {

    var store: BannerStore!

    override func setUp() {
        super.setUp()
        store = BannerStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    func testInitial_isNotVisible() {
        XCTAssertFalse(store.isVisible)
        XCTAssertEqual(store.message, "")
    }

    func testShow_setsMessageAndIsVisible() {
        store.show("Sin conexión")
        XCTAssertEqual(store.message, "Sin conexión")
        XCTAssertTrue(store.isVisible)
    }

    func testDismiss_hidesBanner() {
        store.show("Error de red")
        store.dismiss()
        XCTAssertFalse(store.isVisible)
    }

    func testShow_multipleMessages_usesLatest() {
        store.show("Error 1")
        store.show("Error 2")
        XCTAssertEqual(store.message, "Error 2")
        XCTAssertTrue(store.isVisible)
    }

    func testDismiss_whenNotVisible_doesNotCrash() {
        store.dismiss()
        XCTAssertFalse(store.isVisible)
    }
}
