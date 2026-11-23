//
//  FavoritesStore.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-09.
//

import FirebaseAnalytics
import Foundation


final class FavoritesStore: ObservableObject {
    @Published var favorites: [SRPodFile] = []

    private let key = "favoritePodFiles"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([SRPodFile].self, from: data) {
            favorites = saved
        }
    }

    func toggle(episode: SRPodFile) {
        if let index = favorites.firstIndex(where: { $0.id == episode.id }) {
            favorites.remove(at: index)
            Analytics.logFavoriteToggle(episodeID: episode.id, episodeTitle: episode.title, action: "remove")
        } else {
            favorites.append(episode)
            Analytics.logFavoriteToggle(episodeID: episode.id, episodeTitle: episode.title, action: "add")
        }
        save()
    }

    func isFavorite(id: Int) -> Bool {
        favorites.contains(where: { $0.id == id })
    }

    private func save() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
