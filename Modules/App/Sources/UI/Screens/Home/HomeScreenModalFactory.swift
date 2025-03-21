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

import InboxComposer
import InboxContacts
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

@MainActor
struct HomeScreenModalFactory {
    private let makeContactsScreen: () -> ContactsScreen
    private let makeComposerScreen: (ComposerModalParams) -> ComposerScreen
    private let makeSettingsScreen: () -> SettingsScreen
    private let makeReportProblemScreen: () -> ReportProblemScreen

    init(mailUserSession: MailUserSession, toastStateStore: ToastStateStore) {
        self.makeContactsScreen = {
            ContactsScreen(
                mailUserSession: mailUserSession,
                contactsProvider: .productionInstance(),
                contactsWatcher: .productionInstance(),
                toastStateStore: toastStateStore
            )
        }
        self.makeComposerScreen = { composerParams in
            ComposerScreenFactory.makeComposer(userSession: mailUserSession, composerParams: composerParams)
        }
        self.makeSettingsScreen = { SettingsScreen(mailUserSession: mailUserSession) }
        self.makeReportProblemScreen = { ReportProblemScreen(reportProblemService: mailUserSession) }
    }

    @MainActor @ViewBuilder
    func makeModal(for state: HomeScreen.ModalState) -> some View {
        switch state {
        case .contacts:
            makeContactsScreen()
        case .labelOrFolderCreation:
            CreateFolderOrLabelScreen()
        case .draft(let draftToPresent):
            makeComposerScreen(draftToPresent)
        case .settings:
            makeSettingsScreen()
        case .reportProblem:
            makeReportProblemScreen()
        }
    }
}
