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
import proton_app_uniffi

final class ContactsDraftPresenterSpy: ContactsDraftPresenter {
    var stubbedOpenDraftContactError: Error?
    var stubbedOpenDraftGroupError: Error?

    private(set) var openDraftContactCalls: [SingleRecipientEntry] = []
    private(set) var openDraftGroupCalls: [ContactGroupItem] = []

    // MARK: - ContactsDraftPresenter

    func openDraft(with contact: SingleRecipientEntry) async throws {
        openDraftContactCalls.append(contact)

        if let stubbedOpenDraftContactError {
            throw stubbedOpenDraftContactError
        }
    }

    func openDraft(with group: ContactGroupItem) async throws {
        openDraftGroupCalls.append(group)

        if let stubbedOpenDraftGroupError {
            throw stubbedOpenDraftGroupError
        }
    }
}
