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

import InboxCore
import SwiftUI
import proton_app_uniffi

struct ContactViewFactory {
    let apiConfig: ApiConfig
    let mailUserSession: MailUserSession
    let draftPresenter: ContactsDraftPresenter

    @ViewBuilder
    func makeView(for route: ContactsRoute) -> some View {
        switch route {
        case .contactDetails(let contact):
            ContactDetailsScreen(
                apiConfig: apiConfig,
                contact: contact,
                provider: .productionInstance(mailUserSession: mailUserSession),
                draftPresenter: draftPresenter
            )
        case .contactGroupDetails(let group):
            ContactGroupDetailsScreen(group: group, draftPresenter: draftPresenter)
        }
    }
}
