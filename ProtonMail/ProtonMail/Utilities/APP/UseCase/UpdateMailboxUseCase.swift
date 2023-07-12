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

import Foundation
import ProtonCore_Services

typealias UpdateMailboxUseCase = UseCase<Void, UpdateMailbox.Parameters>

protocol UpdateMailboxSourceProtocol: AnyObject {
    var locationViewMode: ViewMode { get }
}

final class UpdateMailbox: UpdateMailboxUseCase {
    typealias UpdateCompletion = () -> Void
    typealias ErrorHandler = (Error) -> Void

    private(set) var isFetching = false
    private let dependencies: Dependencies
    private weak var sourceDelegate: UpdateMailboxSourceProtocol?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func setup(source: UpdateMailboxSourceProtocol) {
        self.sourceDelegate = source
    }

    /// Set up parameters for test
    func setup(isFetching: Bool) {
        if ProcessInfo.isRunningUnitTests || ProcessInfo.isRunningUITests {
            self.isFetching = isFetching
        }
    }

    override func executionBlock(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        if self.isFetching {
            callback(.success)
            return
        }
        isFetching = true

        guard params.isCleanFetch else {
            scheduledFetch(showUnreadOnly: params.showUnreadOnly,
                           time: params.time,
                           fetchMessagesAtTheEnd: params.fetchMessagesAtTheEnd,
                           errorHandler: params.errorHandler,
                           callback: callback)
            return
        }
        cleanFetch(showUnreadOnly: params.showUnreadOnly,
                   time: params.time,
                   errorHandler: params.errorHandler,
                   callback: callback)
    }

    /// Scheduled task to update inbox / event data
    private func scheduledFetch(showUnreadOnly: Bool,
                                time: Int,
                                fetchMessagesAtTheEnd: Bool,
                                errorHandler: @escaping ErrorHandler,
                                callback: @escaping UseCase<Void, Parameters>.Callback) {

        guard self.isEventIDValid else {
            self.fetchDataWithReset(time: time,
                                    cleanContact: false,
                                    removeAllDraft: false,
                                    unreadOnly: false) { [weak self] error in
                self?.handleFetchMessageResponse(error: error, errorHandler: errorHandler)
                self?.isFetching = false
                callback(.success)
            }
            return
        }

        fetchEvents(
            notificationMessageID: self.notificationMessageID,
            showUnreadOnly: showUnreadOnly,
            time: time,
            fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
            errorHandler: errorHandler,
            callback: callback
        )
    }

    /// Fetch data with cache cleaning
    private func cleanFetch(showUnreadOnly: Bool,
                            time: Int,
                            errorHandler: @escaping ErrorHandler,
                            callback: @escaping UseCase<Void, Parameters>.Callback) {

        self.fetchDataWithReset(time: time,
                                cleanContact: true,
                                removeAllDraft: false,
                                unreadOnly: showUnreadOnly) { [weak self] error in
            self?.handleFetchMessageResponse(error: error, errorHandler: errorHandler)
            self?.isFetching = false
            callback(.success)
        }
    }
}

// MARK: Fetch functions
extension UpdateMailbox {

    private var isEventIDValid: Bool {
        self.dependencies.messageDataService.isEventIDValid()
    }

    private var notificationMessageID: MessageID? {
        if let id = self.dependencies.messageDataService.pushNotificationMessageID {
            return MessageID(id)
        }
        return nil
    }

    private var locationViewMode: ViewMode {
        guard let source = self.sourceDelegate else {
            assert(false, "Needs to set up source")
            return .conversation
        }
        return source.locationViewMode
    }

    private func resetNotificationMessage() {
        self.dependencies.messageDataService.pushNotificationMessageID = nil
    }

    private func fetchEvents(notificationMessageID: MessageID?,
                             showUnreadOnly: Bool,
                             time: Int,
                             fetchMessagesAtTheEnd: Bool,
                             errorHandler: @escaping ErrorHandler,
                             callback: @escaping UseCase<Void, Parameters>.Callback) {

        let labelID = dependencies.labelID
        self.dependencies.eventService
            .fetchEvents(byLabel: labelID,
                         notificationMessageID: notificationMessageID) { [weak self] result in
                self?.handleFetchEventResponse(showUnreadOnly: showUnreadOnly,
                                               time: time,
                                               result: result,
                                               fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                                               errorHandler: errorHandler,
                                               callback: callback)
            }
    }

    private func fetchMessages(time: Int,
                               forceClean: Bool,
                               isUnread: Bool,
                               completion: @escaping (Error?) -> Void) {

        let labelID = dependencies.labelID
        switch self.locationViewMode {
        case .singleMessage:
            self.dependencies
                .fetchMessage
                .execute(
                    params: .init(
                        endTime: time,
                        isUnread: isUnread,
                        onMessagesRequestSuccess: nil
                    ),
                    callback: { result in
                        completion(result.error)
                    }
                )
        case .conversation:
            self.dependencies
                .conversationProvider
                .fetchConversations(for: labelID,
                                    before: time,
                                    unreadOnly: isUnread,
                                    shouldReset: forceClean) { result in
                    switch result {
                    case .success:
                        self.dependencies.conversationProvider
                            .fetchConversationCounts(addressID: nil) { result in
                                switch result {
                                case .success:
                                    completion(nil)
                                case .failure(let error):
                                    completion(error)
                                }
                            }
                    case .failure(let error):
                        completion(error)
                    }
                }
        }
    }

    private func fetchDataWithReset(time: Int,
                                    cleanContact: Bool,
                                    removeAllDraft: Bool,
                                    unreadOnly: Bool,
                                    completion: @escaping (Error?) -> Void) {

        let labelID = dependencies.labelID
        switch self.locationViewMode {
        case .singleMessage:
            let params = FetchMessagesWithReset.Params(
                endTime: time,
                fetchOnlyUnreadMessages: unreadOnly,
                refetchContacts: cleanContact,
                removeAllDrafts: removeAllDraft
            )
            self.dependencies
                .fetchMessageWithReset
                .callbackOn(.main)
                .execute(params: params) { result in
                    completion(result.error)
                }
        case .conversation:
            self.dependencies.fetchLatestEventID.execute(params: ()) { [weak self] fetchLatestEventIDResult in
                if let error = fetchLatestEventIDResult.error {
                    assertionFailure("\(error)")
                }

                guard let localSelf = self else {
                    completion(fetchLatestEventIDResult.error)
                    return
                }

                localSelf.dependencies
                    .conversationProvider
                    .fetchConversations(for: labelID,
                                        before: time,
                                        unreadOnly: unreadOnly,
                                        shouldReset: true) { [weak localSelf] result in
                        guard let localSelf = localSelf else {
                            completion(result.error)
                            return
                        }
                        localSelf.dependencies.conversationProvider
                            .fetchConversationCounts(addressID: nil) { _ in
                                completion(result.error)
                            }
                    }
            }
        }
    }
}

// MARK: Handler functions
extension UpdateMailbox {

    func handleFetchMessageResponse(error: Error?, errorHandler: @escaping ErrorHandler) {
        if let error = error {
            errorHandler(error)
        }
        // temporary to check message status and fetch metadata
        self.dependencies.purgeOldMessages.execute(params: ()) { _ in }
    }

    func handleFetchEventResponse(showUnreadOnly: Bool,
                                  time: Int,
                                  result: Swift.Result<[String: Any], Error>,
                                  fetchMessagesAtTheEnd: Bool,
                                  errorHandler: @escaping ErrorHandler,
                                  callback: @escaping UseCase<Void, Parameters>.Callback) {
        switch result {
        case .failure(let error):
            errorHandler(error)
        case .success(let res):
            self.resetNotificationMessage()
            if let notices = res["Notices"] as? [String] {
                serverNotice.check(notices)
            }

            if let refresh = res["Refresh"] as? Int, refresh > 0 {
                // the client has to re-fetch all models/collection and get the last EventID
                self.cleanFetch(showUnreadOnly: showUnreadOnly,
                                time: time,
                                errorHandler: errorHandler,
                                callback: callback)
                return
            }

            if let more = res["More"] as? Int, more > 0 {
                // it means the client need to call the events route again to receive more updates.
                self.fetchEvents(notificationMessageID: self.notificationMessageID,
                                 showUnreadOnly: showUnreadOnly,
                                 time: time,
                                 fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                                 errorHandler: errorHandler,
                                 callback: callback)
                return
            }
        }

        if fetchMessagesAtTheEnd {
            self.fetchMessages(time: 0, forceClean: false, isUnread: showUnreadOnly) { [weak self] error in
                self?.handleFetchMessageResponse(error: error, errorHandler: errorHandler)
                self?.isFetching = false
                callback(.success)
            }
        } else {
            self.isFetching = false
            callback(.success)
        }
    }
}

extension UpdateMailbox {
    struct Parameters {
        let showUnreadOnly: Bool
        let isCleanFetch: Bool
        let time: Int
        let fetchMessagesAtTheEnd: Bool
        let errorHandler: ErrorHandler
    }

    struct Dependencies {
        let labelID: LabelID
        let eventService: EventsFetching
        let messageDataService: MessageDataServiceProtocol
        let conversationProvider: ConversationProvider
        let purgeOldMessages: PurgeOldMessagesUseCase
        let fetchMessageWithReset: FetchMessagesWithResetUseCase
        let fetchMessage: FetchMessagesUseCase
        let fetchLatestEventID: FetchLatestEventIdUseCase

        init(
            labelID: LabelID,
            eventService: EventsFetching,
            messageDataService: MessageDataServiceProtocol,
            conversationProvider: ConversationProvider,
            purgeOldMessages: PurgeOldMessagesUseCase,
            fetchMessageWithReset: FetchMessagesWithResetUseCase,
            fetchMessage: FetchMessagesUseCase,
            fetchLatestEventID: FetchLatestEventIdUseCase
        ) {
            if labelID == LabelLocation.draft.labelID {
                self.labelID = LabelLocation.hiddenDraft.labelID
            } else if labelID == LabelLocation.sent.labelID {
                self.labelID = LabelLocation.hiddenSent.labelID
            } else {
                self.labelID = labelID
            }
            self.eventService = eventService
            self.messageDataService = messageDataService
            self.conversationProvider = conversationProvider
            self.purgeOldMessages = purgeOldMessages
            self.fetchMessageWithReset = fetchMessageWithReset
            self.fetchMessage = fetchMessage
            self.fetchLatestEventID = fetchLatestEventID
        }
    }
}
