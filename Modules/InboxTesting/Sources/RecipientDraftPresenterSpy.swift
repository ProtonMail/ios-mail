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

public final class RecipientDraftPresenterSpy: @unchecked Sendable, RecipientDraftPresenter {
    public var stubbedOpenDraftError: Error?
    public private(set) var openDraftCalls: [SingleRecipientEntry] = []

    public init() {}

    // MARK: - RecipientDraftPresenter

    public func openDraft(with contact: SingleRecipientEntry) async throws {
        if let stubbedOpenDraftError {
            throw stubbedOpenDraftError
        }

        openDraftCalls.append(contact)
    }
}
