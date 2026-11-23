//
//  AppDelegate.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-18.
//




import SwiftUI
import Firebase
import GoogleSignIn


class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Google Sign In
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(
      _ app: UIApplication,
      open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
      var handled: Bool

    // Handle Sign In With Apple
      handled = GIDSignIn.sharedInstance.handle(url)
      if handled {
        return true
      }

      // Handle other custom URL types.

      // If not handled by this app, return false.
      return false
    }
   
}


