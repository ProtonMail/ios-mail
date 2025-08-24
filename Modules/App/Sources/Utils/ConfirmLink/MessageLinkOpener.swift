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
import SwiftUI

@MainActor
final class MessageLinkOpener {
    private let confirmLink: Bool
    private let confirmationAlert: Binding<AlertModel?>
    private let openURL: URLOpenerProtocol

    init(
        confirmLink: Bool,
        confirmationAlert: Binding<AlertModel?>,
        openURL: URLOpenerProtocol
    ) {
        self.confirmLink = confirmLink
        self.confirmationAlert = confirmationAlert
        self.openURL = openURL
    }

    var action: OpenURLAction {
        .init { url in
            if self.confirmLink {
                self.askForConfirmation(beforeOpening: url)
            } else {
                self.openURL(url)
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
