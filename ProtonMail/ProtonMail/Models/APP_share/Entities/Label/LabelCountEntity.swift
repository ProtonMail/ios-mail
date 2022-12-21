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

struct LabelCountEntity {
    let start: Date?
    let end: Date?
    let update: Date?

    // Used for unread msg filtering
    var unreadStart: Date?
    var unreadEnd: Date?
    var unreadUpdate: Date?

    let total: Int
    let unread: Int

    let viewMode: ViewMode

}

extension LabelCountEntity {
    init(labelCount: LabelCount, viewMode: ViewMode) {
        start = labelCount.start
        end = labelCount.end
        update = labelCount.update

        unreadStart = labelCount.unreadStart
        unreadEnd = labelCount.unreadEnd
        unreadUpdate = labelCount.unreadUpdate

        total = Int(labelCount.total)
        unread = Int(labelCount.unread)

        self.viewMode = viewMode
    }

    var isNew: Bool {
        return start == end && start == update
    }

    var startTime: Date {
        return start ?? .distantPast
    }

    var endTime: Date {
        return end ?? .distantPast
    }

    var isUnreadNew: Bool {
        return unreadStart == unreadEnd && unreadStart == unreadUpdate
    }

    var unreadEndTime: Date {
        return unreadEnd ?? .distantPast
    }
}
