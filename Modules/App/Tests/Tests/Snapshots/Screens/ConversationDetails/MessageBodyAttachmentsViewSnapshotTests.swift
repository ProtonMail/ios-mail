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

@testable import ProtonMail
import InboxTesting
import XCTest

class MessageBodyAttachmentsViewSnapshotTests: BaseTestCase {

    func testShortAttachmentsList() {
        let sut = makeSut(state: .state(attachments: Array([AttachmentDisplayModel].previewData.prefix(3))))
        assertSnapshotsOnIPhoneX(of: sut, named: "short_attachments_list")
    }

    func testLongCollapsedAttachmentsList() {
        let state = MessageBodyAttachmentsState
            .state(attachments: .previewData)

        let sut = makeSut(state: state)
        assertSnapshotsOnIPhoneX(of: sut, named: "long_attachments_list_collapsed")
    }

    func testLongExpandedAttachmentsList() {
        let state = MessageBodyAttachmentsState
            .state(attachments: .previewData)
            .copy(\.listState, to: .long(isAttachmentsListOpen: true))

        let sut = makeSut(state: state)
        assertSnapshotsOnIPhoneX(of: sut, named: "long_attachments_list_expanded")
    }

    // MARK: - Private

    private func makeSut(state: MessageBodyAttachmentsState) -> MessageBodyAttachmentsView {
        .init(state: state, attachmentIDToOpen: .constant(nil))
    }

}
