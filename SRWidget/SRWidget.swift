//
//  SRWidget.swift
//  SRWidget
//
//  Created by Alvar Arias on 2026-05-12.
//

import UIKit
import WidgetKit
import SwiftUI


// MARK: - Widget-local models

private struct ProgramsResponse: Decodable {
    let programs: [Program]
}

private struct Program: Decodable {
    let id: Int
    let name: String
    let programimage: String?
    let programcategory: Category?

    struct Category: Decodable {
        let name: String
    }
}


// MARK: - Entry

struct PodcastEntry: TimelineEntry {
    let date: Date
    let name: String
    let category: String
    let imageData: Data?

    static let placeholder = PodcastEntry(
        date: .now,
        name: "Ekonomiekot",
        category: "Ekonomi och teknik",
        imageData: nil
    )
}


// MARK: - Provider

struct SRWidgetProvider: TimelineProvider {

    private static let url = URL(string: "https://api.sr.se/api/v2/programs/index?format=json&haspod=true&size=100")!

    /// Same exclusions as the Poddar tab: shows that belong to live channels.
    /// Keep in sync with `PodcastViewModel.excludedPrefixes` (the widget is a separate target).
    private static let excludedPrefixes = ["Eftermiddag", "Förmiddag", "Morgon", "Nyheter"]

    func placeholder(in context: Context) -> PodcastEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (PodcastEntry) -> Void) {
        if context.isPreview { completion(.placeholder); return }
        Task {
            completion((try? await fetchEntry()) ?? .placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PodcastEntry>) -> Void) {
        Task {
            let entry = (try? await fetchEntry()) ?? .placeholder
            let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    /// Picks a random podcast with an image, so every refresh shows a different one.
    private func fetchEntry() async throws -> PodcastEntry {
        let (data, _) = try await URLSession.shared.data(from: Self.url)
        let programs = try JSONDecoder().decode(ProgramsResponse.self, from: data).programs

        let eligible = programs.filter { program in
            program.programimage != nil
                && !Self.excludedPrefixes.contains(where: { program.name.hasPrefix($0) })
        }
        guard let program = eligible.randomElement() else { return .placeholder }

        var imageData: Data? = nil
        if let urlString = program.programimage, let imageURL = URL(string: urlString) {
            imageData = try? await URLSession.shared.data(from: imageURL).0
        }

        return PodcastEntry(
            date: .now,
            name: program.name,
            category: program.programcategory?.name ?? "",
            imageData: imageData
        )
    }
}


// MARK: - View

struct SRWidgetEntryView: View {
    let entry: PodcastEntry

    var body: some View {
        ZStack(alignment: .leading) {
            if entry.imageData != nil {
                LinearGradient(
                    colors: [.black.opacity(0.15), .black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "mic")
                        .font(.caption2)
                    Text("Poddtips")
                        .font(.caption2).bold()
                }
                .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text(entry.name)
                    .font(.subheadline).bold()
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if !entry.category.isEmpty {
                    Text(entry.category)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) { backgroundView }
        .widgetURL(URL(string: "srplayer://podcasts"))
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let data = entry.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Color(red: 0x33 / 255, green: 0xA6 / 255, blue: 0xB3 / 255) // app teal (#33A6B3)
        }
    }
}


// MARK: - Widget

struct SRWidget: Widget {
    let kind = "SRWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SRWidgetProvider()) { entry in
            SRWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Poddtips")
        .description("Ett slumpmässigt poddtips från Sveriges Radio.")
        .supportedFamilies([.systemSmall])
    }
}


#Preview(as: .systemSmall) {
    SRWidget()
} timeline: {
    PodcastEntry.placeholder
}
