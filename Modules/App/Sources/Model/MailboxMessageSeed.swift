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

/// Describes the available information when opening the conversation details screen from a push notification
struct MailboxMessageSeed: Hashable {
    /// The type is temporarily set to ID due to the lack of a Rust API for fetching the local message ID for a given remote ID.
    /// It should be reverted back to String when implementing push notifications.
    let remoteID: ID
    let subject: String
    let sender: String
}
