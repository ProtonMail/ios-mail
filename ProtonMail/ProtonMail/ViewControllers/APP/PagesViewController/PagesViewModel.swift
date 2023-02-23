// Copyright (c) 2022 Proton Technologies AG
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
import LifetimeTracker

class PagesViewModel<IDType, EntityType, FetchResultType: NSFetchRequestResult>: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    let viewMode: ViewMode
    let initialID: IDType
    let labelID: LabelID
    let user: UserManager
    /// For conversation mode, which message in this conversation should display
    private var targetMessageID: MessageID?
    let goToDraft: ((MessageID, OriginalScheduleDate?) -> Void)?
    private let isUnread: Bool
    var messageService: MessageDataService { user.messageService }
    var fetchedResultsController: NSFetchedResultsController<FetchResultType>?
    let infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider

    init(
        viewMode: ViewMode,
        isUnread: Bool,
        initialID: IDType,
        labelID: LabelID,
        user: UserManager,
        targetMessageID: MessageID?,
        infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider,
        goToDraft: @escaping ((MessageID, OriginalScheduleDate?) -> Void)
    ) {
        self.labelID = labelID
        self.isUnread = isUnread
        self.user = user
        self.initialID = initialID
        self.viewMode = viewMode
        self.targetMessageID = targetMessageID
        self.infoBubbleViewStatusProvider = infoBubbleViewStatusProvider
        self.goToDraft = goToDraft

        self.fetchedResultsController = prepareFetchedResultsController()
        do {
            try fetchedResultsController?.performFetch()
        } catch { }
        trackLifetime()
    }

    func prepareFetchedResultsController() -> NSFetchedResultsController<FetchResultType>? {
        let isAscending = labelID == LabelLocation.scheduled.labelID ? true : false
        let fetchedResultsController = messageService.fetchedResults(
            by: labelID,
            viewMode: viewMode,
            isUnread: isUnread,
            isAscending: isAscending
        ) as? NSFetchedResultsController<FetchResultType>
        return fetchedResultsController
    }

    /// - Parameters:
    ///   - id: basement query ID, could be messageID or conversationID
    ///   - offset: offset base on given ID
    /// - Returns: (data, reference index)
    /// Message could be inserted or deleted, that value means the index when doing query, only for reference
    func item(for id: IDType, offset: Int) -> (EntityType?, Int?) {
        fatalError("Should not use this class directly")
    }

    func getTargetMessageID() -> MessageID? {
        defer { targetMessageID = nil }
        return targetMessageID
    }
}

final class MessagePagesViewModel: PagesViewModel<MessageID, MessageEntity, Message> {

    init(
        initialID: MessageID,
        isUnread: Bool,
        labelID: LabelID,
        user: UserManager,
        infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider,
        goToDraft: @escaping ((MessageID, OriginalScheduleDate?) -> Void)
    ) {
        super.init(
            viewMode: .singleMessage,
            isUnread: isUnread,
            initialID: initialID,
            labelID: labelID,
            user: user,
            targetMessageID: nil,
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider,
            goToDraft: goToDraft
        )
    }

    override func item(for id: MessageID, offset: Int) -> (MessageEntity?, Int?) {
        guard let messages = fetchedResultsController?.fetchedObjects,
              let targetIndex = messages.firstIndex(where: { $0.messageID == id.rawValue }),
              let object = messages[safe: targetIndex + offset] else { return (nil, nil) }
        return (MessageEntity(object), targetIndex + offset)
    }
}

final class ConversationPagesViewModel: PagesViewModel<ConversationID, ConversationEntity, ContextLabel> {

    init(
        initialID: ConversationID,
        isUnread: Bool,
        labelID: LabelID,
        user: UserManager,
        targetMessageID: MessageID?,
        infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider,
        goToDraft: @escaping ((MessageID, OriginalScheduleDate?) -> Void)
    ) {
        super.init(
            viewMode: .conversation,
            isUnread: isUnread,
            initialID: initialID,
            labelID: labelID,
            user: user,
            targetMessageID: targetMessageID,
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider,
            goToDraft: goToDraft
        )
    }

    override func item(for id: ConversationID, offset: Int) -> (ConversationEntity?, Int?) {
        guard let contextLabels = fetchedResultsController?.fetchedObjects,
              let targetIndex = contextLabels.firstIndex(where: { $0.conversationID == id.rawValue }),
              let context = contextLabels[safe: targetIndex + offset] else { return (nil, nil) }
        let conversation = context.conversation
        return (ConversationEntity(conversation), targetIndex + offset)
    }
}

enum PagesSwipeAction: Int {
    // rawValue is page offset

    // offset = 0, stay in current page
    case noAction = 0
    // offset = 1, switch to next page
    case forward = 1
    // offset = -1, switch to previous page
    case backward = -1
}
