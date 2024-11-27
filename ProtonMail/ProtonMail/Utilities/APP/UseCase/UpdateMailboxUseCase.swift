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
import ProtonCoreServices

typealias UpdateMailboxUseCase = UseCase<Void, UpdateMailbox.Parameters>

// sourcery: mock
protocol UpdateMailboxSourceProtocol: AnyObject {
    var locationViewMode: ViewMode { get }
    var isConversationModeEnabled: Bool { get }
    var messageLocation: Message.Location? { get }
}

final class UpdateMailbox: UpdateMailboxUseCase {
    typealias ErrorHandler = (Error) -> Void

    private(set) var isFetching = false
    private let dependencies: Dependencies
    private let serverNotice: ServerNotice
    private weak var sourceDelegate: UpdateMailboxSourceProtocol?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        serverNotice = .init(userDefaults: dependencies.userDefaults)
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
        SystemLogger.log(
            message: "Requested update, labelID: \(params.labelID), unreadOnly: \(params.showUnreadOnly), cleanFetch: \(params.isCleanFetch), fetchMessagesAtTheEnd: \(params.fetchMessagesAtTheEnd)",
            category: .mailboxRefresh
        )

        if self.isFetching {
            SystemLogger.log(message: "Already fetching", category: .mailboxRefresh)
            callback(.success)
            return
        }
        isFetching = true

        if params.isCleanFetch {
            cleanFetch(params: params, callback: callback)
        } else {
            scheduledFetch(params: params, callback: callback)
        }
    }

    /// Scheduled task to update inbox / event data
    private func scheduledFetch(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        guard self.isEventIDValid else {
            self.fetchDataWithReset(labelID: params.labelID,
                                    cleanContact: false,
                                    unreadOnly: false) { [weak self] error in
                self?.handleFetchMessageResponse(error: error, errorHandler: params.errorHandler)
                self?.markFetchingAsFinished(params: params)
                callback(.success)
            }
            return
        }

        fetchEvents(params: params, callback: callback)
    }

    /// Fetch data with cache cleaning
    private func cleanFetch(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        self.fetchDataWithReset(labelID: params.labelID,
                                cleanContact: true,
                                unreadOnly: params.showUnreadOnly) { [weak self] error in
            self?.handleFetchMessageResponse(error: error, errorHandler: params.errorHandler)
            self?.markFetchingAsFinished(params: params)
            callback(.success)
        }
    }

    private func markFetchingAsFinished(params: Parameters) {
        let key = UserSpecificLabelKey(labelID: params.labelID, userID: params.userID)
        dependencies.userDefaults[.mailboxLastUpdateTimes][key.userDefaultsKey] = Date()
        isFetching = false
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

    private func fetchEvents(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        self.dependencies.eventService
            .fetchEvents(
                byLabel: params.labelID,
                notificationMessageID: notificationMessageID,
                discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled
            ) { [weak self] result in
                self?.handleFetchEventResponse(params: params, result: result, callback: callback)
            }
    }

    private func fetchMessages(labelID: LabelID,
                               forceClean: Bool,
                               isUnread: Bool,
                               completion: @escaping (Error?) -> Void) {
        switch self.locationViewMode {
        case .singleMessage:
            self.dependencies
                .fetchMessage
                .execute(
                    params: .init(
                        labelID: labelID,
                        endTime: 0,
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
                                    before: 0,
                                    unreadOnly: isUnread,
                                    shouldReset: forceClean) { result in
                    switch result {
                    case .success:
                        self.dependencies.conversationProvider
                            .fetchConversationCounts(addressID: nil) { result in
                                completion(result.error)
                            }
                    case .failure(let error):
                        completion(error)
                    }
                }
        }
    }

    private func fetchDataWithReset(labelID: LabelID,
                                    cleanContact: Bool,
                                    unreadOnly: Bool,
                                    completion: @escaping (Error?) -> Void) {
        let shouldFetchConversations: Bool

        switch self.locationViewMode {
        case .singleMessage:
            if let sourceDelegate, sourceDelegate.messageLocation == .sent && sourceDelegate.isConversationModeEnabled {
                shouldFetchConversations = true
            } else {
                shouldFetchConversations = false
            }
        case .conversation:
            shouldFetchConversations = true
        }

        if !shouldFetchConversations {
            let params = FetchMessagesWithReset.Params(
                labelID: labelID,
                fetchOnlyUnreadMessages: unreadOnly,
                refetchContacts: cleanContact
            )
            self.dependencies
                .fetchMessageWithReset
                .callbackOn(.main)
                .execute(params: params) { result in
                    completion(result.error)
                }
        } else {
            self.dependencies.fetchLatestEventID.execute(params: ()) { [weak self] fetchLatestEventIDResult in
                switch fetchLatestEventIDResult {
                case .success(let response):
                    SystemLogger.log(message: "Latest eventID: \(response.eventID)", category: .mailboxRefresh)
                case .failure(let error):
                    SystemLogger.log(error: error, category: .mailboxRefresh)
                }

                guard let localSelf = self else {
                    SystemLogger.log(message: "Mailbox update taking longer than usual", category: .mailboxRefresh)
                    completion(fetchLatestEventIDResult.error)
                    return
                }

                localSelf.dependencies
                    .conversationProvider
                    .fetchConversations(for: labelID,
                                        before: 0,
                                        unreadOnly: unreadOnly,
                                        shouldReset: true) { [weak localSelf] result in
                        if let error = result.error {
                            SystemLogger.log(error: error, category: .mailboxRefresh)
                        }

                        guard let localSelf = localSelf else {
                            SystemLogger.log(message: "Mailbox update taking longer than expected", category: .mailboxRefresh)
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
        // TODO: verify if this temporary call is still necessary
        // temporary to check message status and fetch metadata
        self.dependencies.purgeOldMessages.execute(params: ()) { _ in }
    }

    func handleFetchEventResponse(params: Parameters,
                                  result: Swift.Result<[String: Any], Error>,
                                  callback: @escaping UseCase<Void, Parameters>.Callback) {
        switch result {
        case .failure(let error):
            params.errorHandler(error)
        case .success(let res):
            self.resetNotificationMessage()
            if let notices = res["Notices"] as? [String] {
                serverNotice.check(notices)
            }

            if let refresh = res["Refresh"] as? Int, refresh > 0 {
                // the client has to re-fetch all models/collection and get the last EventID
                SystemLogger.log(message: "Refreshing events", category: .mailboxRefresh)
                cleanFetch(params: params, callback: callback)
                return
            }

            if let more = res["More"] as? Int, more > 0 {
                // it means the client need to call the events route again to receive more updates.
                SystemLogger.log(message: "Need to fetch more events", category: .mailboxRefresh)
                fetchEvents(params: params, callback: callback)
                return
            }
        }

        if params.fetchMessagesAtTheEnd {
            self.fetchMessages(
                labelID: params.labelID,
                forceClean: false,
                isUnread: params.showUnreadOnly
            ) { [weak self] error in
                self?.handleFetchMessageResponse(error: error, errorHandler: params.errorHandler)
                self?.markFetchingAsFinished(params: params)
                self?.dependencies.internetConnectionStatusProvider.apiCallIsSucceeded()
                callback(.success)
            }
        } else {
            markFetchingAsFinished(params: params)
            dependencies.internetConnectionStatusProvider.apiCallIsSucceeded()
            callback(.success)
        }
    }
}

extension UpdateMailbox {
    struct Parameters {
        let labelID: LabelID
        let showUnreadOnly: Bool
        let isCleanFetch: Bool
        let fetchMessagesAtTheEnd: Bool
        let errorHandler: ErrorHandler
        let userID: UserID
    }

    struct Dependencies {
        let eventService: EventsFetching
        let messageDataService: MessageDataServiceProtocol
        let conversationProvider: ConversationProvider
        let purgeOldMessages: PurgeOldMessagesUseCase
        let fetchMessageWithReset: FetchMessagesWithResetUseCase
        let fetchMessage: FetchMessagesUseCase
        let fetchLatestEventID: FetchLatestEventIdUseCase
        let internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol
        let userDefaults: UserDefaults
    }
}
