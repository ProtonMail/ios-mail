// Copyright (c) 2022 Proton AG
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

import CoreData
import Foundation
import PromiseKit
import ProtonCore_TestingToolkit
@testable import ProtonMail

final class MockLocalMessageDataService: LocalMessageDataServiceProtocol {
    private(set) var wasCleanMessageCalled: Bool = false

    private(set) var removeAllDraftValue: Bool = .random()
    private(set) var cleanBadgeAndNotificationsValue: Bool = .random()

    func cleanMessage(removeAllDraft: Bool, cleanBadgeAndNotifications: Bool) -> Promise<Void> {
        wasCleanMessageCalled = true
        removeAllDraftValue = removeAllDraft
        cleanBadgeAndNotificationsValue = cleanBadgeAndNotifications
        return Promise<Void>()
    }

    @FuncStub(MockLocalMessageDataService.fetchMessages, initialReturn: [Message]()) var fetchMessagesStub
    func fetchMessages(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Message] {
        fetchMessagesStub(selected, context)
    }
}
