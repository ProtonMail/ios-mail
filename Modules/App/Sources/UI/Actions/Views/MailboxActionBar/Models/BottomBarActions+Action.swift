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

import proton_app_uniffi

extension BottomBarActions {

    var action: BottomBarAction? {
        switch self {
        case .labelAs:
            return .labelAs
        case .markRead:
            return .markRead
        case .markUnread:
            return .markUnread
        case .more:
            return .more
        case .moveTo:
            return .moveTo
        case .moveToSystemFolder(let label):
            return .moveToSystemFolder(.init(
                localId: .init(value: UInt64(label.rawValue)), // FIXME: - We need to get information about localID
                systemLabel: label.moveToSystemFolderLabel
            ))
        case .notSpam:
            return .notSpam
        case .permanentDelete:
            return .permanentDelete
        case .star:
            return .star
        case .unstar:
            return .unstar
        }
    }

}
