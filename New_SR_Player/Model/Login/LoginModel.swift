//
//  LoginModel.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-18.
//

import FirebaseAnalytics
import FirebaseAuth
import GoogleSignIn


// MARK: - LoginModel
class LoginModel {

    func signInAnonymously(userAuth: UserAuth) {
        Auth.auth().signInAnonymously { _, error in
            if let error = error {
                print("Anonymous sign-in failed:", error)
                return
            }
            Analytics.logLogin(method: "anonymous")
            Task { @MainActor in
                userAuth.isSignedIn = true
            }
        }
    }

    func signInWithEmail(email: String, password: String, userAuth: UserAuth, auth: AuthProtocol = LiveAuth()) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Failed to sign in with email: ", error)
                return
            }
            print("Did sign in with email: ", result?.user.email ?? "No email")
            Analytics.logLogin(method: "email")
            Task { @MainActor in
                userAuth.isSignedIn = true
            }
        }
    }

    @MainActor
    func signInWithGoogle(userAuth: UserAuth) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                print("Google Sign-In failed:", error)
                return
            }
            print("Did sign in with Google:", result?.user.profile?.email ?? "No email")
            Analytics.logLogin(method: "google")
            Task { @MainActor in
                userAuth.isSignedIn = true
            }
        }
    }

}
