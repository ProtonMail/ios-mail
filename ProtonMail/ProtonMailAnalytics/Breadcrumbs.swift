// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

public enum BreadcrumbEvent: String {
    case generic
    case malformedConversationRequest
}

/// In memory object tracing custom information for specific events.
///
/// Use Breadcrumbs to gather information about issues that are difficult to solve.
public class Breadcrumbs {
    public static let shared = Breadcrumbs()

    public struct Crumb {
        public let message: String
        public let timestamp: Date

        var description: String {
            "\(timestamp): \(message)"
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

    public func dumpCrumbs(for event: BreadcrumbEvent) {
        queue.sync {
            guard let events = events[event] else { return }
            print(events.map(\.description).joined(separator: "\n"))
        }
    }
}
