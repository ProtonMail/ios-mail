// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_UIFoundations
import SwiftSoup

extension String {
    struct KeywordHighlightingStringUtils {
        private let originalString: String

        private let highlightColor: UIColor = {
            let color: UIColor = ColorProvider.BrandLighten20
            return color.withAlphaComponent(0.3)
        }()

        // swiftlint:disable:next strict_fileprivate
        fileprivate init(originalString: String) {
            self.originalString = originalString
        }

        func asAttributedString(keywords: [String]) -> NSAttributedString {
            let stringToHighlight = NSMutableAttributedString(string: originalString)
            let highlightColor: UIColor = UIColor.dynamic(light: highlightColor, dark: highlightColor)
            let ranges = nonIntersectingRanges(of: keywords, in: originalString)

            for range in ranges {
                let nsRange = NSRange(range, in: stringToHighlight.string)
                stringToHighlight.addAttribute(.backgroundColor, value: highlightColor, range: nsRange)
            }

            return stringToHighlight
        }

        func usingCSS(keywords: [String]) -> String {
            guard !keywords.isEmpty else {
                return originalString
            }

            // replace occurrences of &nbsp; with normal spaces as it cause problems when highlighting
            var htmlWithHighlightedKeywords = originalString.replacingOccurrences(of: "&nbsp;", with: " ")

            do {
                let doc: Document = try SwiftSoup.parse(htmlWithHighlightedKeywords)

                if let body = doc.body() {
                    try highlightSearchKeyWordsInHtml(parentNode: body, keywords: keywords)
                }

                // fix bug with newlines and whitespaces added
                htmlWithHighlightedKeywords = try documentToHTMLString(document: doc)
            } catch {
                assertionFailure("\(error)")
            }

            return htmlWithHighlightedKeywords
        }

        private func highlightSearchKeyWordsInHtml(parentNode: SwiftSoup.Element, keywords: [String]) throws {
            for node in parentNode.getChildNodes() {
                if let textNode = node as? TextNode {
                    if textNode.isBlank() {
                        continue
                    }
                    if let newElement = try applyMarkUp(textNode: textNode, keywords: keywords) {
                        try node.replaceWith(newElement as Node)
                    }
                } else if let element = node as? SwiftSoup.Element {
                    try self.highlightSearchKeyWordsInHtml(parentNode: element, keywords: keywords)
                }
            }
        }

        private func applyMarkUp(textNode: TextNode, keywords: [String]) throws -> SwiftSoup.Element? {
            let text = textNode.getWholeText().precomposedStringWithCanonicalMapping
            let ranges = nonIntersectingRanges(of: keywords, in: text)

            guard !ranges.isEmpty else {
                return nil
            }

            var span = SwiftSoup.Element(Tag("span"), "")
            var lastIndex = text.startIndex

            for range in ranges {
                span = try span.appendChild(TextNode(String(text[lastIndex ..< range.lowerBound]), ""))

                var markNode = SwiftSoup.Element(Tag("mark"), "")
                try markNode.attr("style", "background-color: #\(highlightColor.rrggbbaa)")
                try markNode.attr("id", "es-autoscroll")

                markNode = try markNode.appendChild(TextNode(String(text[range]), ""))

                span = try span.appendChild(markNode)

                lastIndex = range.upperBound
            }

            if lastIndex < text.endIndex {
                span = try span.appendChild(TextNode(String(text[lastIndex...]), ""))
            }

            return span
        }

        /// Ranges returned by this method are guaranteed not to overlap.
        /// Overlapping ranges are not filtered out, but merged, so all keywords are still fully covered.
        private func nonIntersectingRanges(of keywords: [String], in text: String) -> [Range<String.Index>] {
            let sanitizedText = sanitize(text)
            let sanitizedKeywords = keywords.map(sanitize)

            var ranges = [Range<String.Index>]()

            for keyword in sanitizedKeywords {
                var startingPosition = sanitizedText.startIndex

                while let nextRange = sanitizedText.range(
                    of: keyword,
                    range: startingPosition..<sanitizedText.endIndex
                ) {
                    ranges.append(nextRange)
                    startingPosition = nextRange.upperBound
                }
            }

            // Make sure there are no overlaps when highlighting - if necessary merge the highlighted parts
            return ranges.nonIntersecting()
        }

        private func sanitize(_ string: String) -> String {
            string
                .encryptedSearch.replacingDiacritics()
                .encryptedSearch.replacingDoubleQuotes()
                .encryptedSearch.replacingApostrophes()
                .localizedLowercase
        }

        private func documentToHTMLString(document: Document) throws -> String {
            document.outputSettings().prettyPrint(pretty: false)
            return try document.outerHtml()
        }
    }

    var keywordHighlighting: KeywordHighlightingStringUtils {
        KeywordHighlightingStringUtils(originalString: self)
    }
}

private extension Array where Element == Range<String.Index> {
    func nonIntersecting() -> Self {
        let sortedOccurrences = sorted { $0.lowerBound < $1.lowerBound }

        return sortedOccurrences.reduce(into: []) { resolvedNonIntersectingRanges, nextOccurrence in
            guard !resolvedNonIntersectingRanges.isEmpty else {
                resolvedNonIntersectingRanges.append(nextOccurrence)
                return
            }

            let rightmostResolvedRangeIndex = resolvedNonIntersectingRanges.endIndex - 1
            let rightmostResolvedRange = resolvedNonIntersectingRanges[rightmostResolvedRangeIndex]

            if rightmostResolvedRange.overlaps(nextOccurrence) {
                let upperBoundFarthestToTheRight = Swift.max(
                    rightmostResolvedRange.upperBound,
                    nextOccurrence.upperBound
                )

                resolvedNonIntersectingRanges[rightmostResolvedRangeIndex] = (
                    rightmostResolvedRange.lowerBound ..< upperBoundFarthestToTheRight
                )
            } else {
                resolvedNonIntersectingRanges.append(nextOccurrence)
            }
        }
    }
}
