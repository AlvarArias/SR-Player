//
//  FavoritesView.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-09.
//

import SwiftUI


struct FavoritesView: View {
    @EnvironmentObject var favorites: FavoritesStore
    @StateObject private var vm = PodFileListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if favorites.favorites.isEmpty {
                    ContentUnavailableView(
                        "Inga favoriter",
                        systemImage: "heart",
                        description: Text("Lägg till avsnitt från Poddar-fliken")
                    )
                } else {
                    List(favorites.favorites) { episode in
                        PodFileRow(
                            podFile: episode,
                            isPlaying: vm.playingID == episode.id,
                            isFavorite: true,
                            onPlay: { vm.toggle(podFile: episode) },
                            onFavorite: { favorites.toggle(episode: episode) }
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favoriter")
        }
        .onDisappear { vm.stop() }
    }
}
