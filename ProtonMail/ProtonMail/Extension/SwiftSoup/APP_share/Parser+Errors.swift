// Copyright (c) 2024 Proton Technologies AG
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

import SwiftSoup

extension Parser {
    static func parseAndLogErrors(_ html: String) -> Document? {
        do {
            let document: Document = try parseAndLogErrors(html)
            return document
        } catch {
            SystemLogger.log(error: error, category: .webView)
            return nil
        }
    }

    static func parseAndLogErrors(_ html: String) throws -> Document {
        let parser = htmlParser().setTrackErrors(10)
        let document = try parser.parseInput(html, "")

        for parseError in parser.getErrors().array.compactMap({ $0 }) {
            SystemLogger.log(message: parseError.toString(), category: .webView, isError: true)
        }

        return document
    }
}
