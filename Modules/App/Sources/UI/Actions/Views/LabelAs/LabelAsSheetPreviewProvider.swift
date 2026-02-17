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

@MainActor
enum LabelAsSheetPreviewProvider {
    static func testData() -> LabelAsSheetModel {
        .init(
            input: .init(sheetType: .labelAs, ids: [], mailboxItem: .message(isLastMessageInCurrentLocation: false)),
            mailbox: .init(noHandle: .init()),
            availableLabelAsActions: .init(
                message: { _, _ in .ok(testLabels()) },
                conversation: { _, _ in .ok([]) }
            ),
            labelAsActions: .dummy,
            toastStateStore: .init(initialState: .initial),
            mailUserSession: .dummy,
            dismiss: {}
        )
    }

    static func testLabels() -> [LabelAsAction] {
        [
            .init(
                labelId: .init(value: 1),
                name: "Private",
                color: .init(value: "#F67900"),
                order: 0,
                isSelected: .partial
            ),
            .init(
                labelId: .init(value: 2),
                name: "Personal",
                color: .init(value: "#E93671"),
                order: 1,
                isSelected: .selected
            ),
            .init(
                labelId: .init(value: 3),
                name: "Summer trip",
                color: .init(value: "#9E329A"),
                order: 2,
                isSelected: .unselected
            ),
        ]
    }
}
