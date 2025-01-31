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

struct ComposerContact: Identifiable, Equatable {
    let id: String
    let type: ComposerContactType
    let avatarColor: Color

    init(id: String, type: ComposerContactType, avatarColor: Color) {
        self.id = id
        self.type = type
        self.avatarColor = avatarColor
    }

    var name: String {
        type.name
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

extension ComposerContact {

    var singleContact: ComposerContactSingle? {
        switch type {
        case .single(let single): single
        case .group: nil
        }
    }

    var groupContact: ComposerContactGroup? {
        switch type {
        case .single: nil
        case .group(let group): group
        }
    }
}

enum ComposerContactType: Equatable {
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
}

struct ComposerContactSingle: Equatable {
    let initials: String
    let name: String
    let email: String

    init(initials: String, name: String, email: String) {
        self.initials = initials
        self.name = name
        self.email = email
    }
}

struct ComposerContactGroup: Equatable {
    let name: String
    let totalMembers: Int

    init(name: String, totalMembers: Int) {
        self.name = name
        self.totalMembers = totalMembers
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
