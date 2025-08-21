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
import proton_app_uniffi
import SwiftUI

@MainActor
final class MessageLinkOpener {
    private let mailSettings: () async throws -> MailSettings
    private let confirmationAlert: Binding<AlertModel?>
    private let openURL: URLOpenerProtocol

    init(
        mailSettings: @escaping () async throws -> MailSettings,
        confirmationAlert: Binding<AlertModel?>,
        openURL: URLOpenerProtocol
    ) {
        self.mailSettings = mailSettings
        self.confirmationAlert = confirmationAlert
        self.openURL = openURL
    }

    convenience init(
        mailUserSession: MailUserSession,
        confirmationAlert: Binding<AlertModel?>,
        openURL: URLOpenerProtocol
    ) {
        self.init(
            mailSettings: { try await proton_app_uniffi.mailSettings(ctx: mailUserSession).get() },
            confirmationAlert: confirmationAlert,
            openURL: openURL
        )
    }

    var action: OpenURLAction {
        .init { url in
            Task { [weak self] in
                guard let self else { return }

                do {
                    let settings = try await mailSettings()

                    if settings.confirmLink {
                        askForConfirmation(beforeOpening: url)
                    } else {
                        openURL(url)
                    }
                } catch {
                    AppLogger.log(error: error)
                }
            }
            return .handled
        }
    }

    private func askForConfirmation(beforeOpening url: URL) {
        confirmationAlert.wrappedValue = .openURLConfirmation(url: url) { action in
            self.confirmationAlert.wrappedValue = nil

            switch action {
            case .confirm:
                self.openURL(url)
            case .cancel:
                break
            }
        }
    }
}
