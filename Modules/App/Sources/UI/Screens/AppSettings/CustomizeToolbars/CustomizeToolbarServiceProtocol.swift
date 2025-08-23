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

import proton_app_uniffi

protocol CustomizeToolbarServiceProtocol: Sendable {
    func getListToolbarActions() async throws(ActionError) -> [MobileAction]
    func getMessageToolbarActions() async throws(ActionError) -> [MobileAction]
    func getConversationToolbarActions() async throws(ActionError) -> [MobileAction]

    func updateListToolbarActions(actions: [MobileAction]) async throws(ActionError)
    func updateConversationToolbarActions(actions: [MobileAction]) async throws(ActionError)
    func updateMessageToolbarActions(actions: [MobileAction]) async throws(ActionError)

    func getAllListActions() -> [MobileAction]
    func getAllMessageActions() -> [MobileAction]
    func getAllConversationActions() -> [MobileAction]
}

extension MailUserSession: CustomizeToolbarServiceProtocol {
    func getListToolbarActions() async throws(ActionError) -> [MobileAction] {
        try await getMobileListToolbarActions(session: self).get()
    }

    func getMessageToolbarActions() async throws(ActionError) -> [MobileAction] {
        try await getMobileMessageToolbarActions(session: self).get()
    }

    func getConversationToolbarActions() async throws(ActionError) -> [MobileAction] {
        try await getMobileConversationToolbarActions(session: self).get()
    }

    func updateListToolbarActions(actions: [MobileAction]) async throws(ActionError) {
        try await updateMobileListToolbarActions(session: self, actions: actions).get()
    }

    func updateConversationToolbarActions(actions: [MobileAction]) async throws(ActionError) {
        try await updateMobileConversationToolbarActions(session: self, actions: actions).get()
    }

    func updateMessageToolbarActions(actions: [MobileAction]) async throws(ActionError) {
        try await updateMobileMessageToolbarActions(session: self, actions: actions).get()
    }

    func getAllConversationActions() -> [MobileAction] {
        getAllMobileConversationActions()
    }

    func getAllListActions() -> [MobileAction] {
        getAllMobileListActions()
    }

    func getAllMessageActions() -> [MobileAction] {
        getAllMobileMessageActions()
    }
}
