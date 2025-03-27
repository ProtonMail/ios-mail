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

import InboxCoreUI
import SwiftUI

enum PhishingConfirmationAlertAction: AlertActionProtocol, CaseIterable {
    case cancel
    case confirm
    
    // MARK: - AlertActionProtocol
    
    var title: LocalizedStringResource {
        switch self {
        case .cancel:
            L10n.Common.cancel
        case .confirm:
            L10n.Common.confirm
        }
    }

    var buttonRole: ButtonRole {
        switch self {
        case .cancel:
            .cancel
        case .confirm:
            .destructive
        }
    }
}
