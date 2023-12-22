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

final class UnreadCounterPublisher {
    private var messageCounterPublisher: DataPublisher<LabelUpdate>?
    private var conversationCounterPublisher: DataPublisher<ConversationCount>?
    private let contextProvider: CoreDataContextProviderProtocol
    private let userID: UserID
    private var cancellable: AnyCancellable?

    private(set) var unreadCount: Int = 0

    init(contextProvider: CoreDataContextProviderProtocol, userID: UserID) {
        self.contextProvider = contextProvider
        self.userID = userID
        trackLifetime()
    }

    func startObserve(
        labelID: LabelID,
        viewMode: ViewMode,
        onContentChanged: @escaping (Int) -> Void
    ) {
        switch viewMode {
        case .conversation:
            setupConversationCounterPublisher(
                labelID: labelID,
                onContentChanged: onContentChanged
            )
        case .singleMessage:
            setupMessageCounterPublisher(
                labelID: labelID,
                onContentChanged: onContentChanged
            )
        }
    }

    private func setupConversationCounterPublisher(
        labelID: LabelID,
        onContentChanged: @escaping (Int) -> Void
    ) {
        cancellable?.cancel()
        messageCounterPublisher = nil
        let predicate = NSPredicate(
            format: "(%K == %@) AND (%K == %@)",
            ConversationCount.Attributes.userID,
            userID.rawValue,
            ConversationCount.Attributes.labelID,
            labelID.rawValue
        )
        let sortDescriptors = [
            NSSortDescriptor(
                key: ConversationCount.Attributes.labelID,
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        conversationCounterPublisher = .init(
            entityName: ConversationCount.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            contextProvider: contextProvider
        )
        cancellable = conversationCounterPublisher?.contentDidChange
            .map { $0.map { Int($0.unread) } }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] unreadCounts in
                guard let self = self else { return }
                self.unreadCount = unreadCounts.first ?? 0
                onContentChanged(self.unreadCount)
            })
        conversationCounterPublisher?.start()
    }

    private func setupMessageCounterPublisher(
        labelID: LabelID,
        onContentChanged: @escaping (Int) -> Void
    ) {
        cancellable?.cancel()
        conversationCounterPublisher = nil
        let predicate = NSPredicate(
            format: "(%K == %@) AND (%K == %@)",
            LabelUpdate.Attributes.labelID,
            labelID.rawValue,
            LabelUpdate.Attributes.userID,
            userID.rawValue
        )
        let sortDescriptors = [
            NSSortDescriptor(
                key: LabelUpdate.Attributes.labelID,
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        messageCounterPublisher = .init(
            entityName: LabelUpdate.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            contextProvider: contextProvider
        )
        cancellable = messageCounterPublisher?.contentDidChange
            .map { $0.map { Int($0.unread) } }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] unreadCounts in
                guard let self = self else { return }
                self.unreadCount = unreadCounts.first ?? 0
                onContentChanged(self.unreadCount)
            })
        messageCounterPublisher?.start()
    }
}

extension UnreadCounterPublisher: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
