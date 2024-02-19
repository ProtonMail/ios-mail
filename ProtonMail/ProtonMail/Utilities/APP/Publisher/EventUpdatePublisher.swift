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

import Combine
import CoreData
import LifetimeTracker

final class EventUpdatePublisher {
    private var dataPublisher: DataPublisher<UserEvent>?
    private let contextProvider: CoreDataContextProviderProtocol
    private var cancellable: AnyCancellable?

    init(contextProvider: CoreDataContextProviderProtocol) {
        self.contextProvider = contextProvider
        trackLifetime()
    }

    func startObserve(userID: UserID, onContentChanged: @escaping ([UserEventEntity]) -> Void) {
        let predicate = NSPredicate(
            format: "(%K == %@)",
            UserEvent.Attributes.userID,
            userID.rawValue
        )
        let sortDescriptors = [
            NSSortDescriptor(
                key: UserEvent.Attributes.updateTime,
                ascending: false,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        dataPublisher = .init(
            entityName: UserEvent.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            contextProvider: contextProvider
        )
        cancellable = dataPublisher?.contentDidChange
            .map { $0.map { UserEventEntity(userEvent: $0) } }
            .sink(receiveValue: onContentChanged)
        dataPublisher?.start()
    }
}

extension EventUpdatePublisher: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
