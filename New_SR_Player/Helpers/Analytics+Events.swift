//
//  Analytics+Events.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-12.
//

import FirebaseAnalytics


extension Analytics {
    static func logPodcastPlay(episodeID: Int, episodeTitle: String, action: String) {
        logEvent("podcast_episode_play", parameters: [
            "episode_id": episodeID,
            "episode_title": episodeTitle,
            "action": action
        ])
    }

    static func logFavoriteToggle(episodeID: Int, episodeTitle: String, action: String) {
        logEvent("favorite_toggle", parameters: [
            "episode_id": episodeID,
            "episode_title": episodeTitle,
            "action": action
        ])
    }

    static func logLogin(method: String) {
        logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
}
