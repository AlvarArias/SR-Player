//
//  SRModels.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-06.
//

import Foundation


// MARK: - Programs response

struct SRProgramsResponse: Decodable {
    let programs: [SRProgram]
}

struct SRProgramCategory: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
}

struct SRProgram: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let programimage: String?
    let programcategory: SRProgramCategory?
    let channel: SRProgramChannel?

    struct SRProgramChannel: Decodable {
        let id: Int
        let name: String
    }
}


// MARK: - PodFiles response

struct SRPodFilesResponse: Decodable {
    let podfiles: [SRPodFile]
}

struct SRPodFile: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let duration: Int?
    let url: String?
    let publishdateutc: MicrosoftDate?

    var durationString: String? {
        guard let d = duration, d > 0 else { return nil }
        let min = d / 60
        return min >= 60 ? "\(min / 60) h \(min % 60) min" : "\(min) min"
    }
}


// MARK: - Microsoft JSON date  ("/Date(1234567890000)/")

struct MicrosoftDate: Codable {
    let date: Date

    init(date: Date) { self.date = date }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard
            let open = raw.firstIndex(of: "("),
            let close = raw.firstIndex(of: ")"),
            let ms = Double(raw[raw.index(after: open)..<close])
        else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Invalid Microsoft date: \(raw)"
            )
        }
        date = Date(timeIntervalSince1970: ms / 1000)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let ms = Int64(date.timeIntervalSince1970 * 1000)
        try container.encode("/Date(\(ms))/")
    }
}
