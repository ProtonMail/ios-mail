// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct SearchQueryHelper {
    func sanitizeAndExtractKeywords(query: String) -> [String] {
        let trimmedLowerCase = query.trim().localizedLowercase
        let correctQuotes = findAndReplaceDoubleQuotes(query: trimmedLowerCase)
        let correctApostrophes = findAndReplaceApostrophes(query: correctQuotes)
        let keywords = extractKeywords(query: correctApostrophes)
        return keywords
    }

    private func findAndReplaceDoubleQuotes(query: String) -> String {
        var queryNormalQuotes = query.replacingOccurrences(of: "\u{201C}", with: "\"") // left double quotes
        queryNormalQuotes = queryNormalQuotes.replacingOccurrences(of: "\u{201D}", with: "\"") // right double quotes
        return queryNormalQuotes
    }

    private func findAndReplaceApostrophes(query: String) -> String {
        // left single quotation marks
        var apostrophes = query.replacingOccurrences(of: "\u{2018}", with: "'")
        // right single quotation marks
        apostrophes = apostrophes.replacingOccurrences(of: "\u{2019}", with: "'")
        // single high-reversed-9 quotation mark
        apostrophes = apostrophes.replacingOccurrences(of: "\u{201B}", with: "'")
        return apostrophes
    }

    private func extractKeywords(query: String) -> [String] {
        guard query.contains(check: "\"") else {
            return query.components(separatedBy: " ")
        }
        let keywords: [String] = query.components(separatedBy: "\"")
        return keywords.filter { !$0.isEmpty }
    }
}
