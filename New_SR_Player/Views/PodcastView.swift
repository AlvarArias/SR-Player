//
//  PodcastView.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-09.
//

import AVFoundation
import SwiftUI


// MARK: - CategoryChip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.clear : Color.secondary.opacity(0.4),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - PodcastRow

private struct PodcastRow: View {
    let program: SRProgram
    let language: String?

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: program.programimage ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
                    .overlay(
                        Image(systemName: "mic")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(program.name)
                        .font(.headline)
                    if let lang = language {
                        Text(lang.capitalized)
                            .font(.caption2).fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                if let desc = program.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}


// MARK: - PodcastCarouselCard

private struct PodcastCarouselCard: View {
    let program: SRProgram

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: program.programimage ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "mic")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.4))
                    )
            }
            .frame(maxWidth: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(program.name)
                    .font(.title2).bold()
                    .foregroundColor(.white)
                if let desc = program.description {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}


// MARK: - CarouselEntryModifier

private struct CarouselEntryModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content.offset(y: offset).opacity(opacity)
    }
}


// MARK: - PodcastCarousel

private struct PodcastCarousel: View {
    let programs: [SRProgram]

    var body: some View {
        TabView {
            ForEach(programs) { program in
                NavigationLink(destination: PodFileListView(program: program)) {
                    PodcastCarouselCard(program: program)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 230)
    }
}


// MARK: - PodFileRow

struct PodFileRow: View {
    let podFile: SRPodFile
    let isPlaying: Bool
    let isFavorite: Bool
    let onPlay: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(podFile.title)
                    .font(.subheadline)
                    .lineLimit(2)
                if let dur = podFile.durationString {
                    Text(dur)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(isFavorite ? .red : .gray)
            }
            .buttonStyle(.plain)

            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(isPlaying ? .blue : .gray)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.playPulse)
            .pulsingRing(isActive: isPlaying, color: .blue)
        }
        .padding(.vertical, 4)
    }
}


// MARK: - PodFileListView

struct PodFileListView: View {
    let program: SRProgram
    @StateObject private var vm: PodFileListViewModel
    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var banner: BannerStore

    init(program: SRProgram, apiClient: any SRAPIClientProtocol = SRAPIClient()) {
        self.program = program
        _vm = StateObject(wrappedValue: PodFileListViewModel(apiClient: apiClient))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Laddar avsnitt...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.podFiles.isEmpty {
                ContentUnavailableView("Inga avsnitt", systemImage: "mic.slash")
            } else {
                List(vm.podFiles) { podFile in
                    PodFileRow(
                        podFile: podFile,
                        isPlaying: vm.playingID == podFile.id,
                        isFavorite: favorites.isFavorite(id: podFile.id),
                        onPlay: { vm.toggle(podFile: podFile) },
                        onFavorite: { favorites.toggle(episode: podFile) }
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .task { vm.banner = banner; await vm.load(programID: program.id) }
        .onDisappear { vm.stop() }
    }
}


// MARK: - PodcastTab

struct PodcastTab: View {
    @StateObject private var vm = PodcastViewModel()
    @EnvironmentObject var banner: BannerStore
    @State private var rowsAppeared = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Laddar poddar...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.errorMessage {
                    ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if !vm.featured.isEmpty && vm.searchText.isEmpty && vm.selectedCategory == nil {
                                PodcastCarousel(programs: vm.featured)
                                    .padding(.bottom, 8)
                                    .transition(.modifier(
                                        active: CarouselEntryModifier(offset: 20, opacity: 0),
                                        identity: CarouselEntryModifier(offset: 0, opacity: 1)
                                    ))
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    CategoryChip(title: "Alla", isSelected: vm.selectedCategory == nil) {
                                        vm.selectedCategory = nil
                                    }
                                    ForEach(vm.availableCategories) { cat in
                                        CategoryChip(
                                            title: cat.name,
                                            isSelected: vm.selectedCategory?.id == cat.id
                                        ) {
                                            vm.selectedCategory = vm.selectedCategory?.id == cat.id ? nil : cat
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }

                            Text(vm.filtered.count == vm.programs.count ? "Alla poddar" : "\(vm.filtered.count) program")
                                .font(.title3).bold()
                                .padding(.horizontal)
                                .padding(.vertical, 10)

                            if vm.filtered.isEmpty {
                                ContentUnavailableView.search(text: vm.searchText.isEmpty ? vm.selectedCategory?.name ?? "" : vm.searchText)
                                    .padding(.top, 40)
                            } else {
                                ForEach(Array(vm.filtered.enumerated()), id: \.element.id) { index, program in
                                    NavigationLink(destination: PodFileListView(program: program)) {
                                        PodcastRow(program: program, language: vm.detectedLanguage(for: program))
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(rowsAppeared ? 1 : 0)
                                    .offset(y: rowsAppeared ? 0 : 18)
                                    .animation(
                                        .spring(response: 0.45, dampingFraction: 0.78)
                                            .delay(Double(index) * 0.04),
                                        value: rowsAppeared
                                    )

                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: vm.featured.isEmpty)
                    }
                }
            }
            .navigationTitle("Poddar")
            .searchable(text: $vm.searchText, prompt: "Sök program...")
        }
        .task { vm.banner = banner; await vm.load() }
        .onChange(of: vm.isLoading) { _, isLoading in
            if !isLoading { withAnimation { rowsAppeared = true } }
        }
    }
}
