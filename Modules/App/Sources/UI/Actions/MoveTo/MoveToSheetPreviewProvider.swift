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

import SwiftUI

enum MoveToSheetPreviewProvider {

    static var testData: MoveToState {
        .init(
            moveToSystemFolderActions: [
                .init(id: .init(value: 1), label: .inbox, isSelected: .unselected),
                .init(id: .init(value: 2), label: .archive, isSelected: .unselected),
            ],
            moveToCustomFolderActions: [
                .init(id: .init(value: 3), name: "1", color: Color(hex: "#F67900"), isSelected: .unselected, children: [
                    .init(id: .init(value: 4), name: "2", color: Color(hex: "#E93672"), isSelected: .unselected, children: [
                        .init(id: .init(value: 5), name: "3", color: Color(hex: "#9E329A"), isSelected: .selected, children: [])
                    ])
                ]),
                .init(id: .init(value: 6), name: "4", color: Color(hex: "#9E221A"), isSelected: .unselected, children: [])
            ]
        )
    }

}
