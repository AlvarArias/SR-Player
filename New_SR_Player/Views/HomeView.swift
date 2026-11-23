//
//  HomeView.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-05.
//

import AVFoundation
import SwiftUI


// MARK: - TopBar

private struct TopBar: View {
    var body: some View {
        HStack {
            Image(systemName: "radio")
                .font(.title2)
            Text("SR Radio")
                .font(.title2).bold()
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}


// MARK: - FeaturedCard

private struct FeaturedCard: View {
    let channel: SRChannel
    let episode: SRScheduleEpisode?
    let tagline: String
    let song: SRSong?
    let isPlaying: Bool
    let isBuffering: Bool
    let onPlay: () -> Void

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "sv_SE")
        return f
    }()

    private var timeRange: String? {
        guard let ep = episode else { return nil }
        return "\(Self.timeFmt.string(from: ep.starttimeutc.date)) – \(Self.timeFmt.string(from: ep.endtimeutc.date))"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(channel.swiftColor)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(channel.name)
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        if isPlaying && !isBuffering {
                            EqualizerView(color: .white)
                                .padding(.bottom, 4)
                        }
                    }
                    if let time = timeRange {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text(tagline)
                        .font(.subheadline).bold()
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    if let song = song {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.caption2)
                            Text("\(song.artist) — \(song.title)")
                                .lineLimit(1)
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                    } else if let desc = episode?.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    Spacer()
                    Button(action: onPlay) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(channel.swiftColor)
                            .contentTransition(.symbolEffect(.replace))
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.playPulse)
                    .pulsingRing(isActive: isBuffering, color: .white)
                }
                .padding(24)

                Spacer()

                AsyncImage(url: URL(string: episode?.imageurl ?? channel.image ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: channel.sfSymbol)
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.trailing, 20)
                .padding(.top, 24)
            }
        }
        .frame(minHeight: 210)
    }
}


// MARK: - ChannelRow

struct ChannelRow: View {
    let channel: SRChannel
    let episode: SRScheduleEpisode?
    let tagline: String
    let song: SRSong?
    let isPlaying: Bool
    let isBuffering: Bool
    let onPlay: () -> Void

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "sv_SE")
        return f
    }()

    private var timeRange: String? {
        guard let ep = episode else { return nil }
        return "\(Self.timeFmt.string(from: ep.starttimeutc.date)) – \(Self.timeFmt.string(from: ep.endtimeutc.date))"
    }

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: episode?.imageurl ?? channel.image ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                channel.swiftColor
                    .overlay(
                        Image(systemName: channel.sfSymbol)
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.headline)
                Text(tagline)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let song = song {
                    HStack(spacing: 3) {
                        Image(systemName: "music.note")
                            .font(.system(size: 9))
                        Text("\(song.artist) — \(song.title)")
                            .lineLimit(1)
                    }
                    .font(.caption2)
                    .foregroundColor(channel.swiftColor)
                }
                if let time = timeRange {
                    Text(time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if isPlaying && !isBuffering {
                EqualizerView(color: channel.swiftColor)
            }

            Spacer()

            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(isPlaying ? channel.swiftColor : .gray)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.playPulse)
            .pulsingRing(isActive: isBuffering, color: channel.swiftColor)
        }
        .padding(.vertical, 4)
    }
}


// MARK: - VäderRow

private struct VäderRow: View {
    let episode: SRPodFile
    let isPlaying: Bool
    let onPlay: () -> Void

    private static let inputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd HH:mm"
        f.locale = Locale(identifier: "sv_SE")
        return f
    }()

    private static let outputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM · HH:mm"
        f.locale = Locale(identifier: "sv_SE")
        return f
    }()

    private var parsedTitle: String {
        episode.title.replacing(/\s*\d{8}\s+\d{2}:\d{2}.*/, with: "")
    }

    private var parsedDate: String? {
        guard let match = episode.title.firstMatch(of: /(\d{8}) (\d{2}:\d{2})/) else { return nil }
        let raw = "\(match.1) \(match.2)"
        guard let date = Self.inputFormatter.date(from: raw) else { return nil }
        return Self.outputFormatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "cloud.sun.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 56, height: 56)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(parsedTitle)
                    .font(.headline)
                if let date = parsedDate {
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(isPlaying ? .blue : .gray)
            }
            .pulsingRing(isActive: isPlaying, color: .blue)
        }
        .padding(.vertical, 4)
    }
}


// MARK: - HomeTab

private struct HomeTab: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var banner: BannerStore
    @State private var rowsAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            Divider()
            if vm.isLoading {
                Spacer()
                ProgressView("Laddar kanaler...")
                Spacer()
            } else if let featured = vm.featured {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        FeaturedCard(
                            channel: featured,
                            episode: vm.nowPlaying[featured.id],
                            tagline: vm.tagline(for: featured),
                            song: vm.currentSong(for: featured),
                            isPlaying: vm.playingChannelID == featured.id,
                            isBuffering: vm.bufferingChannelID == featured.id,
                            onPlay: { vm.togglePlay(id: featured.id) }
                        )

                        HStack {
                            Text("Populära kanaler")
                                .font(.title3).bold()
                            Spacer()
                            Button {} label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(vm.listed.enumerated()), id: \.element.id) { index, channel in
                                ChannelRow(
                                    channel: channel,
                                    episode: vm.nowPlaying[channel.id],
                                    tagline: vm.tagline(for: channel),
                                    song: vm.currentSong(for: channel),
                                    isPlaying: vm.playingChannelID == channel.id,
                                    isBuffering: vm.bufferingChannelID == channel.id,
                                    onPlay: { vm.togglePlay(id: channel.id) }
                                )
                                .opacity(rowsAppeared ? 1 : 0)
                                .offset(y: rowsAppeared ? 0 : 18)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.78)
                                        .delay(Double(index) * 0.07),
                                    value: rowsAppeared
                                )
                                if channel.id != vm.listed.last?.id {
                                    Divider().padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color(white: 1.0))
                        .cornerRadius(16)

                        if let episode = vm.vaderEpisode {
                            Text("Väder")
                                .font(.title3).bold()

                            VStack(spacing: 0) {
                                VäderRow(
                                    episode: episode,
                                    isPlaying: vm.vaderIsPlaying,
                                    onPlay: { vm.toggleVader() }
                                )
                            }
                            .padding()
                            .background(Color(white: 1.0))
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
                .background(Color(white: 0.95))
            }
        }
        .task { vm.banner = banner; await vm.load() }
        .onChange(of: vm.isLoading) { _, isLoading in
            if !isLoading { withAnimation { rowsAppeared = true } }
        }
    }
}


// MARK: - AppTab

private enum AppTab: Int, CaseIterable {
    case home, podcasts, favorites, profile

    var title: String {
        switch self {
        case .home:      return "Hem"
        case .podcasts:  return "Poddar"
        case .favorites: return "Favoriter"
        case .profile:   return "Profil"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .podcasts:  return "mic"
        case .favorites: return "heart.fill"
        case .profile:   return "person.fill"
        }
    }
}


// MARK: - CustomTabBar

private struct CustomTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                            .symbolEffect(.bounce, value: selected == tab)
                        Text(tab.title)
                            .font(.caption2)
                    }
                    .foregroundStyle(selected == tab ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.regularMaterial)
        .overlay(Divider(), alignment: .top)
    }
}


// MARK: - HomeView

struct HomeView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            HomeTab()
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)

            PodcastTab()
                .opacity(selectedTab == .podcasts ? 1 : 0)
                .allowsHitTesting(selectedTab == .podcasts)

            FavoritesView()
                .opacity(selectedTab == .favorites ? 1 : 0)
                .allowsHitTesting(selectedTab == .favorites)

            ProfileView()
                .opacity(selectedTab == .profile ? 1 : 0)
                .allowsHitTesting(selectedTab == .profile)
        }
        .animation(.easeInOut(duration: 0.22), value: selectedTab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selected: $selectedTab)
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
