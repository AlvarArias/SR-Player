//
//  HomeView.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-05.
//

import SwiftUI


// MARK: - AppTab

private enum AppTab: Int, CaseIterable {
    case podcasts, favorites, profile

    var title: String {
        switch self {
        case .podcasts:  return "Poddar"
        case .favorites: return "Favoriter"
        case .profile:   return "Profil"
        }
    }

    var icon: String {
        switch self {
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
    @State private var selectedTab: AppTab = .podcasts

    var body: some View {
        ZStack {
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
