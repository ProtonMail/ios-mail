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

import AccountLogin
import InboxContacts
import InboxCore
import InboxIAP
import PaymentsUI
import SwiftUI
import proton_app_uniffi

@MainActor
struct HomeScreenModalFactory {
    private let makeContactsScreen: (ContactsDraftPresenter) -> ContactsScreen
    private let makeSettingsScreen: () -> SettingsScreen
    private let makeReportProblemScreen: () -> ReportProblemScreen
    private let makeSubscriptionsScreen: () -> SubscriptionsScreen

    init(mailUserSession: MailUserSession, accountAuthCoordinator: AccountAuthCoordinator, upsellCoordinator: UpsellCoordinator) {
        self.makeContactsScreen = { draftPresenter in
            ContactsScreen(
                apiConfig: .current,
                mailUserSession: mailUserSession,
                contactsProvider: .productionInstance(),
                contactsWatcher: .productionInstance(),
                draftPresenter: draftPresenter
            )
        }
        self.makeSettingsScreen = {
            SettingsScreen(
                mailUserSession: mailUserSession,
                accountAuthCoordinator: accountAuthCoordinator,
                upsellCoordinator: upsellCoordinator
            )
        }
        self.makeReportProblemScreen = { ReportProblemScreen(reportProblemService: mailUserSession) }
        self.makeSubscriptionsScreen = { AvailablePlansViewFactory.make(mailUserSession: mailUserSession, presentationMode: .modal) }
    }

    @ViewBuilder
    func makeModal(for state: HomeScreen.ModalState, draftPresenter: ContactsDraftPresenter) -> some View {
        switch state {
        case .contacts:
            makeContactsScreen(draftPresenter)
        case .labelOrFolderCreation:
            CreateFolderOrLabelScreen()
        case .settings:
            makeSettingsScreen()
        case .reportProblem:
            makeReportProblemScreen()
        case .subscriptions:
            makeSubscriptionsScreen()
        case .upsell(let model):
            UpsellScreen(model: model)
        }
    }
}
