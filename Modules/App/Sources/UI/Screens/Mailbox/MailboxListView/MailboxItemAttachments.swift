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

/// A summary of attachments associated with a mailbox item.
struct MailboxItemAttachments {
    /// Attachments that can be directly previewed in the mailbox list
    /// (e.g., images, PDFs, or text documents).
    let previewable: [AttachmentCapsuleUIModel]

    /// Indicates whether the mail contains a calendar invitation
    /// (i.e., an `.ics` attachment).
    let containsCalendarInvitation: Bool

    /// The total number of attachments, regardless of type or previewability.
    let totalCount: Int

    /// Indicates whether the mail has *any* attachments.
    /// This is derived from `totalCount`.
    var hasAny: Bool { totalCount > 0 }
}
