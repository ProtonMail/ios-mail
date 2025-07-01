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

@testable import InboxComposer
import proton_app_uniffi
import Testing

final class DraftAttachmentArrayTests {

    @Test
    func testToDraftAttachmentUIModels_itShouldFilterOutInlineDispositionAttachments() throws {
        let sut: [DraftAttachment] = [
            .makeMockDraftAttachment(name: "attach_1", state: .uploaded, disposition: .attachment),
            .makeMockDraftAttachment(name: "attach_2", state: .uploaded, disposition: .inline),
            .makeMockDraftAttachment(name: "attach_3", state: .uploading, disposition: .attachment),
            .makeMockDraftAttachment(name: "attach_4", state: .error(.reason(.crypto)), disposition: .attachment),
            .makeMockDraftAttachment(name: "attach_5", state: .offline, disposition: .attachment),
            .makeMockDraftAttachment(name: "attach_6", state: .pending, disposition: .attachment),
            .makeMockDraftAttachment(name: "attach_7", state: .pending, disposition: .inline),
        ]

        let result = sut.toDraftAttachmentUIModels()
        let expectedNames = ["attach_1", "attach_3", "attach_4", "attach_5", "attach_6"]
        #expect(result.map(\.attachment.name) == expectedNames)
    }
}
