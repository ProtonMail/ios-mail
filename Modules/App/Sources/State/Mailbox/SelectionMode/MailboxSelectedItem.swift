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

/// Represents a selected item in the mailbox.
///
/// **Important:** `isRead` and `isStarred` are included to enable reactive toolbar updates.
/// They are not accessed directly, but they affect `Hashable` equality, which allows
/// `.onChange(of: selectedItems)` to detect when item states change and trigger toolbar refresh.
///  This allow to react to changes made offline but also to react to changes made remotely.
struct MailboxSelectedItem: Hashable {
    let id: ID

    /// Whether the item is read. Included in equality to trigger toolbar updates when changed.
    let isRead: Bool

    /// Whether the item is starred. Included in equality to trigger toolbar updates when changed.
    let isStarred: Bool
}
