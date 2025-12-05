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

extension DraftAttachment {
    static func makeMock(
        id: UInt64 = .random(in: 0..<UInt64.max),
        state: DraftAttachmentState,
        timestamp: Int64
    ) -> DraftAttachment {
        DraftAttachment(
            state: state,
            attachment: makeMockMetadata(attachmentId: .init(value: id)),
            stateModifiedTimestamp: timestamp
        )
    }

    static func makeMockMetadata(attachmentId: Id) -> AttachmentMetadata {
        return .init(
            id: attachmentId,
            disposition: .attachment,
            mimeType: .init(mime: "", category: .pdf),
            name: "attachment",
            size: 1,
            isListable: false
        )
    }
}
