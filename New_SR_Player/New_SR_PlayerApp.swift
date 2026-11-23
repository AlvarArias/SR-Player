//
//  New_SR_PlayerApp.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2023-12-15.
//

import SwiftUI
import Firebase
import GoogleSignIn


@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var userAuth = UserAuth()
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var banner = BannerStore()

    var body: some Scene {
        WindowGroup {
            SplashPage()
                .environmentObject(userAuth)
                .environmentObject(favorites)
                .environmentObject(banner)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        guard error == nil, user != nil else { return }
                        Task { @MainActor in
                            userAuth.isSignedIn = true
                        }
                    }
                }
        }
    }
}





