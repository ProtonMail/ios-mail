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

import Foundation
import struct SwiftUI.Color

struct ComposerContact: Identifiable, Equatable, Filterable {
    let id: String
    let type: ComposerContactType
    let avatarColor: Color

    init(type: ComposerContactType, avatarColor: Color) {
        self.id = type.toMatch.joined(separator: ",")
        self.type = type
        self.avatarColor = avatarColor
    }

    var name: String {
        type.name
    }

    var toMatch: [String] {
        type.toMatch
    }

    func toUIModel(alreadySelected: Bool = false) -> ComposerContactUIModel {
        switch type {
        case .single(let single):
            return ComposerContactUIModel(
                avatar: .initials(single.initials),
                avatarColor: avatarColor,
                isGroup: false,
                title: single.name,
                subtitle: single.email,
                alreadySelected: alreadySelected
            )
        case .group(let group):
            return ComposerContactUIModel(
                avatar: .group,
                avatarColor: avatarColor,
                isGroup: true,
                title: group.name,
                subtitle: L10n.Contacts.groupSubtitle(membersCount: group.totalMembers).string,
                alreadySelected: alreadySelected
            )
        }
    }
}

enum ComposerContactType: Equatable, Filterable {
    case single(ComposerContactSingle)
    case group(ComposerContactGroup)

    var isGroup: Bool {
        switch self {
        case .single: false
        case .group: true
        }
    }

    var name: String {
        switch self {
        case .single(let single): single.name
        case .group(let group): group.name
        }
    }

    var toMatch: [String] {
        switch self {
        case .single(let single): single.toMatch
        case .group(let group): group.toMatch
        }
    }
}

struct ComposerContactSingle: Equatable, Filterable {
    let initials: String
    let name: String
    let nameToMatch: String
    let email: String
    let emailToMatch: String

    init(initials: String? = nil, name: String? = nil, email: String) {
        self.email = email
        self.emailToMatch = self.email.toContactMatchFormat()
        self.initials = initials ?? email.first?.description.uppercased() ?? "" // FIXME:
        self.name = name ?? email
        self.nameToMatch = self.name.toContactMatchFormat()
    }

    var toMatch: [String] {
        [nameToMatch, emailToMatch]
    }
}

struct ComposerContactGroup: Equatable, Filterable {
    let name: String
    let nameToMatch: String
    let totalMembers: Int

    init(name: String, totalMembers: Int) {
        self.name = name
        self.nameToMatch = self.name.toContactMatchFormat()
        self.totalMembers = totalMembers
    }

    var toMatch: [String] {
        [nameToMatch]
    }
}

enum ComposerContactAvatar {
    case initials(String)
    case group

    var initials: String? {
        switch self {
        case .initials(let value):
            value
        case .group:
            nil
        }
    }
}
