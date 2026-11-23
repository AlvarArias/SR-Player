//
//  UserAuth.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-18.
//

import FirebaseAuth
import GoogleSignIn


// MARK: - AuthProtocol
protocol AuthProtocol {
    func signIn(withEmail email: String, password: String, completion: (@Sendable (AuthDataResult?, Error?) -> Void)?)
}

final class LiveAuth: AuthProtocol {
    func signIn(withEmail email: String, password: String, completion: (@Sendable (AuthDataResult?, Error?) -> Void)?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }
}


// MARK: - UserAuth
@MainActor
class UserAuth: ObservableObject {
    @Published var isSignedIn = false

    func signOut() {
        try? Auth.auth().signOut()
        if GIDSignIn.sharedInstance.currentUser != nil {
            GIDSignIn.sharedInstance.signOut()
        }
        isSignedIn = false
    }
}
