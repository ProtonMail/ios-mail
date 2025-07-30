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

@testable import ProtonMail
import InboxSnapshotTesting
import InboxTesting
import XCTest

@MainActor
class MessageBodyAttachmentsViewSnapshotTests: XCTestCase {
    func testShortAttachmentsList() {
        let sut = makeSUT(state: .state(attachments: Array([AttachmentDisplayModel].previewData.prefix(3))))
        assertSelfSizingSnapshot(of: sut, named: "short_attachments_list")
    }

    func testLongCollapsedAttachmentsList() {
        let sut = makeSUT(state: .state(attachments: .previewData))

        assertSelfSizingSnapshot(of: sut, named: "long_attachments_list_collapsed")
    }

    func testLongExpandedAttachmentsList() {
        let sut = makeSUT(
            state: .state(attachments: .previewData).copy(\.listState, to: .long(isAttachmentsListOpen: true))
        )

        assertSelfSizingSnapshot(of: sut, named: "long_attachments_list_expanded")
    }

    // MARK: - Private

    private func makeSUT(state: MessageBodyAttachmentsState) -> MessageBodyAttachmentsView {
        .init(state: state, attachmentIDToOpen: .constant(nil))
    }
}
