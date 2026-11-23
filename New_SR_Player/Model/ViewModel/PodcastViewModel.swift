//
//  PodcastViewModel.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-11.
//

import SwiftUI


@MainActor
final class PodcastViewModel: ObservableObject {
    @Published var programs: [SRProgram] = []
    @Published var featured: [SRProgram] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: SRProgramCategory? = nil

    var banner: BannerStore?
    private let apiClient: any SRAPIClientProtocol
    private let searchService = ProgramSearchService()
    private var languageCache: [Int: String] = [:]

    init(apiClient: any SRAPIClientProtocol = SRAPIClient()) {
        self.apiClient = apiClient
    }

    private static let excludedPrefixes = ["Eftermiddag", "Förmiddag", "Morgon", "Nyheter"]

    var availableCategories: [SRProgramCategory] {
        var seen = Set<Int>()
        return programs.compactMap { $0.programcategory }.filter { seen.insert($0.id).inserted }
            .sorted { $0.name < $1.name }
    }

    func detectedLanguage(for program: SRProgram) -> String? {
        languageCache[program.id]
    }

    var filtered: [SRProgram] {
        var result = searchService.filter(programs, query: searchText)
        if let cat = selectedCategory {
            result = result.filter { $0.programcategory?.id == cat.id }
        }
        return result
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let all = try await apiClient.fetchPrograms()
            programs = all.filter { program in
                !Self.excludedPrefixes.contains(where: { program.name.hasPrefix($0) })
            }
            featured = Array(programs.shuffled().prefix(5))
            for program in programs {
                if let lang = searchService.detectedLanguage(for: program) {
                    languageCache[program.id] = lang
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            banner?.show("Kunde inte ladda poddar — kontrollera nätverket")
        }
    }
}
