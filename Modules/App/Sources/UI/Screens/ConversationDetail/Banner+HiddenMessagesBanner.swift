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

import InboxCoreUI
import InboxDesignSystem

extension Banner {
    static func nonTrashed(toggleAction: @escaping (Bool) -> Void) -> Banner {
        hiddenMessagesBanner(title: "Show non-trashed messages in this conversation", toggleAction: toggleAction)
    }

    static func trashed(toggleAction: @escaping (Bool) -> Void) -> Banner {
        hiddenMessagesBanner(title: "Show trashed messages in this conversation.", toggleAction: toggleAction)
    }

    private static func hiddenMessagesBanner(title: String, toggleAction: @escaping (Bool) -> Void) -> Banner {
        .init(
            icon: DS.Icon.icTrash,
            title: title,
            subtitle: nil,
            size: .small(.toggle(.init(title: title, isOn: false, action: toggleAction))),
            style: .regular
        )
    }
}
