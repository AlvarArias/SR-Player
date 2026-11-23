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

private struct ChannelDetailResponse: Decodable {
    let channel: ChannelDetail
    struct ChannelDetail: Decodable {
        let color: String
    }
}

private struct MicrosoftDate: Decodable {
    let date: Date
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard
            let open  = raw.firstIndex(of: "("),
            let close = raw.firstIndex(of: ")"),
            let ms    = Double(raw[raw.index(after: open)..<close])
        else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Invalid Microsoft date: \(raw)"
            )
        }
        date = Date(timeIntervalSince1970: ms / 1000)
    }
}

private struct ScheduleEpisode: Decodable {
    let title: String
    let starttimeutc: MicrosoftDate
    let endtimeutc: MicrosoftDate
    let imageurl: String?
}

private struct ScheduleResponse: Decodable {
    let schedule: [ScheduleEpisode]
}


// MARK: - Entry

struct ChannelEntry: TimelineEntry {
    let date: Date
    let channelName: String
    let colorHex: String
    let programTitle: String
    let timeRange: String
    let imageData: Data?

    static let placeholder = ChannelEntry(
        date: .now,
        channelName: "P1",
        colorHex: "EED096",
        programTitle: "Kaliber",
        timeRange: "10:00 – 11:00",
        imageData: nil
    )
}


// MARK: - Provider

struct SRWidgetProvider: TimelineProvider {

    private static let channelID   = 132
    private static let channelName = "P1"
    private static let base        = "https://api.sr.se/api/v2"

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "sv_SE")
        return f
    }()

    func placeholder(in context: Context) -> ChannelEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (ChannelEntry) -> Void) {
        if context.isPreview { completion(.placeholder); return }
        Task {
            completion((try? await fetchEntry()) ?? .placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChannelEntry>) -> Void) {
        Task {
            let entry = (try? await fetchEntry()) ?? .placeholder
            let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    private func fetchEntry() async throws -> ChannelEntry {
        let channelURL  = URL(string: "\(Self.base)/channels/\(Self.channelID)?format=json")!
        let scheduleURL = URL(string: "\(Self.base)/scheduledepisodes?channelid=\(Self.channelID)&format=json&size=100")!

        async let channelFetch  = URLSession.shared.data(from: channelURL)
        async let scheduleFetch = URLSession.shared.data(from: scheduleURL)

        let (channelData, _)  = try await channelFetch
        let (scheduleData, _) = try await scheduleFetch

        let colorHex = (try? JSONDecoder().decode(ChannelDetailResponse.self, from: channelData))?.channel.color ?? "EED096"

        let response = try JSONDecoder().decode(ScheduleResponse.self, from: scheduleData)
        let now = Date()
        let episode = response.schedule.first(where: { $0.starttimeutc.date <= now && $0.endtimeutc.date >= now })
            ?? response.schedule.filter { $0.starttimeutc.date <= now }.max(by: { $0.starttimeutc.date < $1.starttimeutc.date })

        guard let ep = episode else {
            return ChannelEntry(date: now, channelName: Self.channelName, colorHex: colorHex,
                                programTitle: Self.channelName, timeRange: "", imageData: nil)
        }

        let range = "\(Self.timeFmt.string(from: ep.starttimeutc.date)) – \(Self.timeFmt.string(from: ep.endtimeutc.date))"

        var imageData: Data? = nil
        if let urlString = ep.imageurl, let imageURL = URL(string: urlString) {
            imageData = try? await URLSession.shared.data(from: imageURL).0
        }

        return ChannelEntry(date: now, channelName: Self.channelName, colorHex: colorHex,
                            programTitle: ep.title, timeRange: range, imageData: imageData)
    }
}


// MARK: - View

struct SRWidgetEntryView: View {
    let entry: ChannelEntry

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
                    Image(systemName: "radio")
                        .font(.caption2)
                    Text(entry.channelName)
                        .font(.caption2).bold()
                }
                .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text(entry.programTitle)
                    .font(.subheadline).bold()
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if !entry.timeRange.isEmpty {
                    Text(entry.timeRange)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) { backgroundView }
        .widgetURL(URL(string: "srplayer://channel/132"))
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let data = entry.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            channelColor
        }
    }

    private var channelColor: Color {
        var int: UInt64 = 0
        Scanner(string: entry.colorHex).scanHexInt64(&int)
        return Color(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}


// MARK: - Widget

struct SRWidget: Widget {
    let kind = "SRWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SRWidgetProvider()) { entry in
            SRWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SR P1")
        .description("Visa aktuellt program på P1.")
        .supportedFamilies([.systemSmall])
    }
}


#Preview(as: .systemSmall) {
    SRWidget()
} timeline: {
    ChannelEntry.placeholder
}
