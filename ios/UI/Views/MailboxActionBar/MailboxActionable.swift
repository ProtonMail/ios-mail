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

protocol MailboxActionable {

    @MainActor
    func labelsOfSelectedItems() -> [Set<PMLocalLabelId>]

    @MainActor
    func onActionTap(_ action: Action)

    @MainActor
    func onLabelsSelected(labelIds: Set<PMLocalLabelId>, alsoArchive: Bool)

    @MainActor
    func onFolderSelected(labelId: PMLocalLabelId)
}

struct EmptyMailboxActionable: MailboxActionable {
    func labelsOfSelectedItems() -> [Set<PMLocalLabelId>] { [] }
    func onActionTap(_ action: Action) {}
    func onLabelsSelected(labelIds: Set<PMLocalLabelId>, alsoArchive: Bool) {}
    func onFolderSelected(labelId: PMLocalLabelId) {}
}
