// Copyright (c) 2022 Proton AG
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

public enum BreadcrumbEvent: String {
    case generic
    case malformedConversationRequest
    case randomLogout
    case inconsistentBody
    case malformedConversationLabelRequest
}

/// In memory object tracing custom information for specific events.
///
/// Use Breadcrumbs to gather information about issues that are difficult to solve.
public class Breadcrumbs {
    public static let shared = Breadcrumbs()

    public struct Crumb {
        static private var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter
        }()

        public let message: String
        public let timestamp: Date

        var description: String {
            "\(Self.dateFormatter.string(from: timestamp)) \(message)"
        }
    }

    private let queue = DispatchQueue(label: "ch.protonmail.breadcrumbs")
    private var events = [BreadcrumbEvent: [Crumb]]()
    let maxCrumbs = 15

    public func add(message: String, to event: BreadcrumbEvent) {
        let newCrumb = Crumb(message: message, timestamp: Date())
        queue.sync {
            var crumbs = events[event] ?? []
            crumbs.append(newCrumb)
            if crumbs.count > maxCrumbs {
                crumbs = Array(crumbs.dropFirst())
            }
            events[event] = crumbs
        }
    }

    public func crumbs(for event: BreadcrumbEvent) -> [Crumb]? {
        queue.sync {
            return events[event]
        }
    }

    public func trace(for event: BreadcrumbEvent) -> String? {
        return crumbs(for: event)?
            .reversed()
            .map(\.description)
            .joined(separator: "\n")
    }
}
