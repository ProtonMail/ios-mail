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
    private static let queryItemValueSeparator = ","

    static func encode(route: Route) -> URL {
        var components = URLComponents()
        components.scheme = route.urlScheme.rawValue

        switch route {
        case .composer(fromShareExtension: false):
            components.host = "composer"
        case .composer(fromShareExtension: true):
            components.host = "composerFromShareExtension"
        case .mailbox(.systemFolder(let localID, let remoteID)):
            components.host = "mailbox"
            components.path = "/system"

            components.queryItems = [
                .init(name: "localID", value: "\(localID.value)"),
                .init(name: "remoteID", value: "\(remoteID.rawValue)"),
            ]
        case .mailbox:
            fatalError("Encoding arbitrary mailbox is not supported.")
        case .mailboxOpenMessage(let seed):
            components.host = "messages"

            components.path = "/\(seed.remoteId.value)"

            components.queryItems = [
                .init(name: "subject", value: seed.subject)
            ]
        case .mailto:
            fatalError("Encoding mailto is not supported.")
        case .search:
            components.host = "search"
        }

        return components.url!
    }

    static func decode(deepLink: URL) -> Route? {
        guard
            let components = URLComponents(url: deepLink, resolvingAgainstBaseURL: true),
            let rawScheme = components.scheme,
            let supportedScheme = Bundle.URLScheme(rawValue: rawScheme)
        else {
            return nil
        }

        switch supportedScheme {
        case .mailto:
            return decodeMailtoRoute(from: components)
        case .protonmail:
            return decodeProtonMailRoute(from: components)
        }
    }

    private static func decodeMailtoRoute(from components: URLComponents) -> Route {
        let data = MailtoData(
            to: components.path.components(separatedBy: queryItemValueSeparator),
            cc: multipleValuesFromQueryItem(named: "cc", from: components),
            bcc: multipleValuesFromQueryItem(named: "bcc", from: components),
            subject: components.queryItem(named: "subject"),
            body: components.queryItem(named: "body")
        )

        return .mailto(data)
    }

    private static func multipleValuesFromQueryItem(named name: String, from components: URLComponents) -> [String] {
        guard let rawValue: String = components.queryItem(named: name) else {
            return []
        }

        return rawValue.components(separatedBy: queryItemValueSeparator)
    }

    private static func decodeProtonMailRoute(from components: URLComponents) -> Route? {
        switch components.host {
        case "composer":
            return .composer(fromShareExtension: false)
        case "composerFromShareExtension":
            return .composer(fromShareExtension: true)
        case "mailbox":
            guard
                components.path == "/system",
                let rawLocalID: UInt64 = components.queryItem(named: "localID"),
                let rawRemoteID: UInt8 = components.queryItem(named: "remoteID"),
                let systemFolder = SystemLabel(rawValue: rawRemoteID)
            else {
                return nil
            }

            let localID = ID(value: rawLocalID)
            return .mailbox(selectedMailbox: .systemFolder(labelId: localID, systemFolder: systemFolder))
        case "messages":
            let pathRegex = /\/([:ascii:]+)/

            guard
                let match = try? pathRegex.wholeMatch(in: components.path),
                let subject: String = components.queryItem(named: "subject")
            else {
                return nil
            }

            let remoteId = RemoteId(value: .init(match.output.1))
            return .mailboxOpenMessage(seed: .init(remoteId: remoteId, subject: subject))
        case "search":
            return .search
        default:
            return nil
        }
    }
}

private extension URLComponents {
    func queryItem<ValueType: LosslessStringConvertible>(named name: String) -> ValueType? {
        guard let rawValue = queryItems?.first(where: { $0.name == name })?.value else {
            return nil
        }

        return ValueType(rawValue)
    }
}
