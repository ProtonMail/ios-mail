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

import Foundation
import InboxCore
import proton_app_uniffi

struct AppProtectionMethodViewModel: Equatable {
    let type: MethodType
    var isSelected: Bool

    enum MethodType {
        case `none`
        case pin
        case faceID
        case touchID

        var name: LocalizedStringResource {
            switch self {
            case .none:
                "None"
            case .pin:
                "PIN code"
            case .faceID:
                "Face ID"
            case .touchID:
                "Touch ID"
            }
        }
    }
}

extension AppProtectionMethodViewModel.MethodType {

    var appProtection: AppProtection {
        switch self {
        case .none:
            .none
        case .pin:
            .pin
        case .faceID, .touchID:
            .biometrics
        }
    }

}
