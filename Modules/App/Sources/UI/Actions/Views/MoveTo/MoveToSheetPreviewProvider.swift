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
import SwiftUI

enum MoveToSheetPreviewProvider {

    static var availableMoveToActions: AvailableMoveToActions {
        .init(
            message: { _, _ in
                .ok([
                    .systemFolder(.init(localId: .init(value: 1), name: .inbox)),
                    .systemFolder(.init(localId: .init(value: 2), name: .archive)),
                    .customFolder(customFoldersTree),
                    .customFolder(
                        .init(
                            localId: .init(value: 6),
                            name: "4",
                            color: .init(value: "#9E221A"),
                            children: []
                        )),
                ])
            },
            conversation: { _, _ in .ok([]) }
        )
    }

    // MARK: - Private

    private static var customFoldersTree: CustomFolderAction {
        .init(
            localId: .init(value: 3),
            name: "1",
            color: .init(value: "#F67900"),
            children: [
                .init(
                    localId: .init(value: 4),
                    name: "2",
                    color: .init(value: "#E93672"),
                    children: [
                        .init(
                            localId: .init(value: 5),
                            name: "3",
                            color: .init(value: "#9E329A"),
                            children: []
                        )
                    ]
                )
            ]
        )
    }

}
