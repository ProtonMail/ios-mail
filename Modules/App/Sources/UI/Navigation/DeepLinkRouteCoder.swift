// Copyright (c) 2025 Proton Technologies AG
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
import proton_app_uniffi

enum DeepLinkRouteCoder {
    private static let deepLinkScheme = Bundle.URLScheme.protonmail

    static func encode(route: Route) -> URL? {
        var components = URLComponents()
        components.scheme = deepLinkScheme.rawValue

        switch route {
        case .mailbox:
            return nil // no need to support this now
        case .mailboxOpenMessage(let seed):
            components.host = "messages"

            components.path = "/\(seed.remoteId.value)"

            components.queryItems = [
                .init(name: "subject", value: seed.subject)
            ]
        }

        return components.url
    }

    static func decode(deepLink: URL) -> Route? {
        guard
            let components = URLComponents(url: deepLink, resolvingAgainstBaseURL: true)
        else {
            return nil
        }

        switch components.host {
        case "messages":
            let pathRegex = /\/([:ascii:]+)/

            guard
                let match = try? pathRegex.wholeMatch(in: components.path),
                let subject = components.queryItems?.first(where: { $0.name == "subject" })?.value
            else {
                return nil
            }

            let remoteId = RemoteId(value: .init(match.output.1))
            return .mailboxOpenMessage(seed: .init(remoteId: remoteId, subject: subject))
        default:
            return nil
        }

    }
}
