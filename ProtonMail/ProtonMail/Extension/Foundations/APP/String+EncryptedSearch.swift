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

import Foundation

extension String {
    struct EncryptedSearchStringUtils {
        private let originalString: String

        // swiftlint:disable:next strict_fileprivate
        fileprivate init(originalString: String) {
            self.originalString = originalString
        }

        func replacingDiacritics() -> String {
            let stringWithManuallyReplacedCharacters = replacingOccurrences(
                of: [
                    "\u{0141}", // polish Ł
                    "\u{0142}"  // polish ł
                ],
                with: "l"
            )
            return stringWithManuallyReplacedCharacters.folding(
                options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive],
                locale: nil
            )
        }

        func replacingDoubleQuotes() -> String {
            replacingOccurrences(
                of: [
                    "\u{201C}", // left double quotes
                    "\u{201D}"  // right double quotes
                ],
                with: "\""
            )
        }

        func replacingApostrophes() -> String {
            replacingOccurrences(
                of: [
                    "\u{2018}", // left single quotation marks
                    "\u{2019}", // right single quotation marks
                    "\u{201B}"  // single high-reversed-9 quotation mark
                ],
                with: "'"
            )
        }

        func replacingOccurrences(of targets: [String], with replacement: String) -> String {
            targets.reduce(into: originalString) { acc, target in
                acc = acc.replacingOccurrences(of: target, with: replacement)
            }
        }
    }

    var encryptedSearch: EncryptedSearchStringUtils {
        EncryptedSearchStringUtils(originalString: self)
    }
}
