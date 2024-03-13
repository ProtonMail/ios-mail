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

import CoreData
import Foundation

final class SaveEventResponseInCacheUseCase {
    typealias Dependencies = AnyObject
        & HasCoreDataContextProviderProtocol
        & HasQueueManager
        & HasContactDataService

    unowned let dependencies: Dependencies
    private let encoder = JSONEncoder()
    private let contactEventProcessor: ContactEventProcessor
    private let emailEventProcessor: EmailEventProcessor
    private let labelEventProcessor: LabelEventProcessor
    private let conversationProcessor: ConversationEventProcessor
    private let messageProcessor: MessageEventProcessor

    init(dependencies: Dependencies, userID: UserID) {
        self.dependencies = dependencies
        self.contactEventProcessor = .init(
            dependencies: dependencies,
            userID: userID,
            encoder: encoder
        )
        self.emailEventProcessor = .init(userID: userID, encoder: encoder)
        self.labelEventProcessor = .init(userID: userID)
        self.conversationProcessor = .init(userID: userID, encoder: encoder)
        self.messageProcessor = .init(
            userID: userID,
            encoder: encoder,
            queueManager: dependencies.queueManager
        )
    }

    func execute(
        response: EventAPIResponse,
        discardContactsMetadata: Bool = EventCheckRequest.isNoMetaDataForContactsEnabled
    ) throws {
        try dependencies.contextProvider.write { context in
            self.labelEventProcessor.process(response: response, context: context)
            if discardContactsMetadata {
                self.contactEventProcessor.precessWithoutMetadata(response: response, context: context)
            } else {
                self.contactEventProcessor.process(response: response, context: context)
            }
            self.emailEventProcessor.process(response: response, context: context)
            self.conversationProcessor.process(response: response, context: context)
            self.messageProcessor.process(response: response, context: context)
        }
    }
}
