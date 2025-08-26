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

extension Array where Element == AttachmentDisplayModel {

    static var previewData: Self {
        [
            .init(
                id: .init(value: 1),
                mimeType: .init(mime: "pdf", category: .pdf),
                name: "CV",
                size: 1200
            ),
            .init(
                id: .init(value: 2),
                mimeType: .init(mime: "img", category: .image),
                name: "My photo",
                size: 12000
            ),
            .init(
                id: .init(value: 3),
                mimeType: .init(mime: "doc", category: .pages),
                name: "Covering letter",
                size: 120000
            ),
            .init(
                id: .init(value: 3),
                mimeType: .init(mime: "doc", category: .pages),
                name: "Long long long long long long long long long long name",
                size: 120000
            ),
        ]
    }

}
