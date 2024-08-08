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

protocol UpdateMailboxSourceProtocol: AnyObject {
    var locationViewMode: ViewMode { get }
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
        if self.isFetching {
            callback(.success)
            return
        }
        isFetching = true

        guard params.isCleanFetch else {
            scheduledFetch(params: params, callback: callback)
            return
        }
        cleanFetch(params: params, callback: callback)
    }

    /// Scheduled task to update inbox / event data
    private func scheduledFetch(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {

        guard self.isEventIDValid else {
            self.fetchDataWithReset(time: params.time,
                                    labelID: params.labelID,
                                    cleanContact: false,
                                    unreadOnly: false) { [weak self] error in
                self?.handleFetchMessageResponse(error: error, errorHandler: params.errorHandler)
                self?.markFetchingAsFinished(params: params)
                callback(.success)
            }
            return
        }

        fetchEvents(notificationMessageID: self.notificationMessageID, params: params, callback: callback)
    }

    /// Fetch data with cache cleaning
    private func cleanFetch(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        self.fetchDataWithReset(time: params.time,
                                labelID: params.labelID,
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

    private func fetchEvents(notificationMessageID: MessageID?,
                             params: Parameters,
                             callback: @escaping UseCase<Void, Parameters>.Callback) {
        self.dependencies.eventService
            .fetchEvents(
                byLabel: params.labelID,
                notificationMessageID: notificationMessageID,
                discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled
            ) { [weak self] result in
                self?.handleFetchEventResponse(params: params, result: result, callback: callback)
            }
    }

    private func fetchMessages(time: Int,
                               labelID: LabelID,
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
                                    labelID: LabelID,
                                    cleanContact: Bool,
                                    unreadOnly: Bool,
                                    completion: @escaping (Error?) -> Void) {
        switch self.locationViewMode {
        case .singleMessage:
            let params = FetchMessagesWithReset.Params(
                labelID: labelID,
                endTime: time,
                fetchOnlyUnreadMessages: unreadOnly,
                refetchContacts: cleanContact
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
                cleanFetch(params: params, callback: callback)
                return
            }

            if let more = res["More"] as? Int, more > 0 {
                // it means the client need to call the events route again to receive more updates.
                self.fetchEvents(notificationMessageID: self.notificationMessageID,
                                 params: params,
                                 callback: callback)
                return
            }
        }

        if params.fetchMessagesAtTheEnd {
            self.fetchMessages(
                time: 0,
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
        let time: Int
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
