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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ErrorScreen: View {
    @Environment(\.openURL) private var openURL

    let error: Error
    let dismissExtension: () -> Void

    init(error: any Error, dismissExtension: @escaping () -> Void) {
        self.error = error
        self.dismissExtension = dismissExtension
    }

    var body: some View {
        VStack(spacing: DS.Spacing.extraLarge) {
            Spacer()

            Text(errorMessage)
                .multilineTextAlignment(.center)

            Spacer()

            if error.shouldPromptToSignIn {
                Button(L10n.openApp.string) {
                    openURL(URL(string: "\(Bundle.URLScheme.protonmail):")!)
                    dismissExtension()
                }
            }

            Button(CommonL10n.cancel.string) {
                dismissExtension()
            }
        }
        .buttonStyle(BigButtonStyle())
        .padding(DS.Spacing.huge)
        .padding(.vertical, DS.Spacing.extraLarge)
        .background(DS.Color.BackgroundInverted.norm)
    }

    private var errorMessage: String {
        if error.shouldPromptToSignIn {
            L10n.needToSignIn.string
        } else {
            error.localizedDescription
        }
    }
}

private extension Error {
    var shouldPromptToSignIn: Bool {
        switch self as? UserSessionError {
        case .reason(.userSessionNotInitialized):
            true
        default:
            false
        }
    }
}

#Preview("with sign-in option") {
    ErrorScreen(error: UserSessionError.reason(.userSessionNotInitialized), dismissExtension: {})
}

#Preview("without sign-in option") {
    ErrorScreen(error: NSError(domain: "", code: 0), dismissExtension: {})
}
