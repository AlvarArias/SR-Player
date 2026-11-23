//
//  New_SR_PlayerTests.swift
//  New_SR_PlayerTests
//
//  Created by Alvar Arias on 2024-04-19.
//

import XCTest
import FirebaseAuth
@testable import New_SR_Player


// MARK: - MockAuth
class MockAuth: AuthProtocol {
    var shouldReturnError = false
    var signInWasCalled = false

    func signIn(withEmail email: String, password: String, completion: (@Sendable (AuthDataResult?, Error?) -> Void)?) {
        signInWasCalled = true
        if shouldReturnError {
            completion?(nil, NSError(domain: "MockAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock sign-in error"]))
        } else {
            completion?(nil, nil)
        }
    }
}


// MARK: - Tests
@MainActor
final class New_SR_PlayerTests: XCTestCase {

    var loginModel: LoginModel!
    var userAuth: UserAuth!
    var mockAuth: MockAuth!

    override func setUp() {
        super.setUp()
        mockAuth = MockAuth()
        loginModel = LoginModel()
        userAuth = UserAuth()
    }

    override func tearDown() {
        loginModel = nil
        userAuth = nil
        mockAuth = nil
        super.tearDown()
    }

    func testSignInWithEmail_callsAuth() {
        loginModel.signInWithEmail(email: "test@test.com", password: "password", userAuth: userAuth, auth: mockAuth)
        XCTAssertTrue(mockAuth.signInWasCalled)
    }

    func testSignInWithEmail_success_setsIsSignedIn() async {
        mockAuth.shouldReturnError = false
        loginModel.signInWithEmail(email: "test@test.com", password: "password", userAuth: userAuth, auth: mockAuth)
        await Task.yield()
        XCTAssertTrue(userAuth.isSignedIn)
    }

    func testSignInWithEmail_failure_doesNotSetIsSignedIn() {
        mockAuth.shouldReturnError = true
        loginModel.signInWithEmail(email: "test@test.com", password: "password", userAuth: userAuth, auth: mockAuth)
        XCTAssertFalse(userAuth.isSignedIn)
    }

}
