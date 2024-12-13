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

struct MailboxLabelUIModel: Identifiable {
    let labelModels: [LabelUIModel]

    var id: ID {
        labelModels.first?.labelId ?? .random()
    }

    var color: Color {
        labelModels.first?.color ?? .clear
    }

    var text: String {
        labelModels.first?.text ?? ""
    }

    var numExtraLabels: Int {
        labelModels.count - 1
    }

    var isEmpty: Bool {
        labelModels.isEmpty
    }

    init(labelModels: [LabelUIModel] = []) {
        self.labelModels = labelModels
    }
}

struct LabelUIModel: Hashable {
    let labelId: ID
    let text: String
    let color: Color
}
