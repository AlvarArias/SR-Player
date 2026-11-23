//
//  ProgramSearchService.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-21.
//

import Foundation
import NaturalLanguage


// MARK: - ProgramSearchService

/// Filters SR programs using NLTokenizer with Swedish locale for proper
/// word-boundary detection and diacritic-insensitive matching.
struct ProgramSearchService {

    private let tokenizer: NLTokenizer = {
        let t = NLTokenizer(unit: .word)
        t.setLanguage(.swedish)
        return t
    }()

    /// Returns programs whose name or description contains every token in `query`.
    func filter(_ programs: [SRProgram], query: String) -> [SRProgram] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return programs }
        let tokens = tokenize(trimmed)
        return programs.filter { matches($0, tokens: tokens) }
    }

    private func matches(_ program: SRProgram, tokens: [String]) -> Bool {
        let combined = [program.name, program.description ?? ""].joined(separator: " ")
        let normalized = normalize(combined)
        return tokens.allSatisfy { normalized.contains($0) }
    }

    private func tokenize(_ text: String) -> [String] {
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = normalize(String(text[range]))
            if !word.isEmpty { tokens.append(word) }
            return true
        }
        return tokens.isEmpty ? [normalize(text)] : tokens
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "sv_SE"))
    }

    // MARK: Language detection

    /// Returns the localized Swedish name of the program's language if it is
    /// not Swedish (e.g. "finska", "arabiska"). Returns nil for Swedish or
    /// when the text is too short for a reliable result.
    func detectedLanguage(for program: SRProgram) -> String? {
        let text = [program.name, program.description ?? ""].joined(separator: " ")
        guard text.count >= 15 else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard
            let hypotheses = recognizer.languageHypotheses(withMaximum: 1).first,
            hypotheses.value >= 0.70,
            hypotheses.key != .swedish,
            hypotheses.key != .undetermined
        else { return nil }

        return Locale(identifier: "sv_SE").localizedString(forLanguageCode: hypotheses.key.rawValue)
    }
}
