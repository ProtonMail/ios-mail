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
import SwiftUI

public struct ErrorView: View {
    let error: Error
    let dismissExtension: () -> Void
    let launchMainApp: () async -> Void

    public init(error: any Error, dismissExtension: @escaping () -> Void, launchMainApp: @escaping () async -> Void) {
        self.error = error
        self.dismissExtension = dismissExtension
        self.launchMainApp = launchMainApp
    }

    public var body: some View {
        VStack(spacing: DS.Spacing.extraLarge) {
            Spacer()

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)

            Spacer()

            if error.shouldPromptToSignIn {
                Button(L10n.openApp.string) {
                    Task {
                        await launchMainApp()
                        dismissExtension()
                    }
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
}

private extension Error {
    var shouldPromptToSignIn: Bool {
        switch self as? MailUserSessionFactoryError {
        case .notSignedIn: true
        default: false
        }
    }
}

#Preview("with sign-in option") {
    ErrorView(error: MailUserSessionFactoryError.notSignedIn, dismissExtension: {}, launchMainApp: {})
}

#Preview("without sign-in option") {
    ErrorView(error: NSError(domain: "", code: 0), dismissExtension: {}, launchMainApp: {})
}
