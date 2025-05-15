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

enum PINScreenType: Hashable, Identifiable {
    case set
    case confirm(pin: String)
    case verify(reason: PINVerificationReason)

    struct Configuration {
        let pinInputTitle: LocalizedStringResource
        let screenTitle: LocalizedStringResource
        let trailingButtonTitle: LocalizedStringResource
    }

    var configuration: Configuration {
        switch self {
        case .set:
            .init(
                pinInputTitle: L10n.Settings.App.setPINInputTitle,
                screenTitle: L10n.Settings.App.setPINScreenTitle,
                trailingButtonTitle: L10n.Common.next
            )
        case .confirm:
            .init(
                pinInputTitle: L10n.Settings.App.repeatPIN,
                screenTitle: L10n.Settings.App.repeatPIN,
                trailingButtonTitle: CommonL10n.confirm
            )
        case .verify(let reason):
            switch reason {
            case .changePIN:
                .verify(screenTitle: L10n.Settings.App.changePINcode, trailingButtonTitle: L10n.Common.next)
            case .disablePIN:
                .verify(screenTitle: L10n.Settings.App.disablePINScreenTitle, trailingButtonTitle: CommonL10n.confirm)
            }
        }
    }

    var isCodeHintVisible: Bool {
        switch self {
        case .set:
            true
        case .confirm, .verify:
            false
        }
    }

    var id: PINScreenType {
        self
    }
}

private extension PINScreenType.Configuration {

    static func verify(screenTitle: LocalizedStringResource, trailingButtonTitle: LocalizedStringResource) -> Self {
        .init(
            pinInputTitle: L10n.Settings.App.verifyPINInputTitle,
            screenTitle: screenTitle,
            trailingButtonTitle: trailingButtonTitle
        )
    }

}
