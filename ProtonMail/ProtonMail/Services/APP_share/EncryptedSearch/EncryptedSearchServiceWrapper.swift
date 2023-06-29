// Copyright (c) 2023 Proton Technologies AG
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

import Foundation

protocol EncryptedSearchServiceWrapperProtocol {
    func remove(messageIDs: [MessageID], for userID: UserID)
    func update(drafts: [MessageEntity], for userID: UserID)
    func fetchNewerMessage(for userID: UserID)
    func rebuildSearchIndex(for userID: UserID)
}

// Workaround for EventsService, EventsService has share target and it is not easy to remove
// Rely on this wrapper to send events from EventsService
final class EncryptedSearchServiceWrapper: EncryptedSearchServiceWrapperProtocol {

    func remove(messageIDs: [MessageID], for userID: UserID) {
        #if !APP_EXTENSION
            EncryptedSearchService.shared.remove(messageIDs: messageIDs, for: userID)
        #endif
    }

    func update(drafts: [MessageEntity], for userID: UserID) {
        #if !APP_EXTENSION
            EncryptedSearchService.shared.update(drafts: drafts, for: userID)
        #endif
    }

    func fetchNewerMessage(for userID: UserID) {
        #if !APP_EXTENSION
            EncryptedSearchService.shared.fetchNewerMessageIfNeeded(for: userID)
        #endif
    }

    func rebuildSearchIndex(for userID: UserID) {
        #if !APP_EXTENSION
            EncryptedSearchService.shared.rebuildSearchIndex(for: userID)
        #endif
    }
}
