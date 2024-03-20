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
import class UIKit.UIImage

enum Route: Equatable {
    case mailbox(label: SelectedMailbox)
    case settings

    var selectedMailbox: SelectedMailbox? {
        if case .mailbox(let label) = self {
            return label
        }
        return nil
    }

    var localLabelId: PMLocalLabelId? {
        if case .mailbox(let label) = self {
            return label.localId
        }
        return nil
    }

    var screenTitle: String {
        switch self {
        case .mailbox(let label):
            return label.name
        case .settings:
            return LocalizationTemp.settings
        }
    }
}

