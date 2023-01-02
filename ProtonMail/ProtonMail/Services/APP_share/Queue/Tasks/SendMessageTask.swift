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
import struct ProtonCore_Networking.ResponseError
import class ProtonCore_Services.APIErrorCode

/// Object responsible for triggering the actual send action. SendMessageTask also
/// manages anything related to the before and after of the actual send request,
/// specifically alerts/notifications and error management.
class SendMessageTask {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func run(params: Params, completion: @escaping (Error?) -> Void) {
        do {
            try beforeSendingMessage(userID: params.userID)
            let initialSendingData = try getMessageSendingData(for: params.messageURI)

            updateMessageDetails(
                messageSendingData: initialSendingData,
                userID: params.userID
            ) { [unowned self] updatedSendingData in
                sendMessage(messageSendingData: updatedSendingData, params: params) { [unowned self] sendResult in
                    switch sendResult {
                    case .failure(let error):
                        let finalError = afterSendingMessageFailure(message: updatedSendingData.message, error: error)
                        completion(finalError)
                    case .success:
                        afterSendingMessageSuccess(message: updatedSendingData.message, params: params)
                        completion(nil)
                    }
                }
            }

        } catch {
            SystemLogger.log(message: "Error: \(error)", category: .sendMessage, isError: true)
            completion(error)
        }
    }

    /// Logic related to prerequisites, user alerts/notifications or queue flow
    private func beforeSendingMessage(userID: UserID) throws {
        try ensureUserIsAuthenticated(userID)
    }

    private func ensureUserIsAuthenticated(_ userID: UserID) throws {
        guard dependencies.isUserAuthenticated(userID) else {
            throw NSError.userLoggedOut()
        }
    }

    private func getMessageSendingData(for messageURI: String) throws -> MessageSendingData {
        guard let messageSendingData = dependencies.messageDataService.getMessageSendingData(for: messageURI) else {
            throw SendMessageTaskError.noMessageFoundForURI
        }
        let message = "MessageID = \(messageSendingData.message.messageID.rawValue)"
        SystemLogger.log(message: message, category: .sendMessage)
        return messageSendingData
    }

    private func updateMessageDetails(
        messageSendingData: MessageSendingData,
        userID: UserID,
        completion: @escaping (MessageSendingData) -> Void
    ) {
        dependencies.fetchMessageDetail.execute(params: .init(
            userID: userID,
            message: messageSendingData.message,
            hasToBeQueued: false
        )) { result in
            switch result {
            case .success(let message):
                SystemLogger.log(message: "Fetched message detail success", category: .sendMessage)
                let newMessageSendingData = MessageSendingData(
                    message: message,
                    cachedUserInfo: messageSendingData.cachedUserInfo,
                    cachedAuthCredential: messageSendingData.cachedAuthCredential,
                    cachedSenderAddress: messageSendingData.cachedSenderAddress,
                    defaultSenderAddress: messageSendingData.defaultSenderAddress
                )
                completion(newMessageSendingData)
            case .failure(let error):
                let message = "Fetched message detail error: \(error)"
                SystemLogger.log(message: message, category: .sendMessage, isError: true)
                completion(messageSendingData)
            }
        }
    }

    private func sendMessage(
        messageSendingData: MessageSendingData,
        params: Params,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let params = SendMessage.Params(
            messageSendingData: messageSendingData,
            scheduleSendDeliveryTime: params.deliveryTime,
            undoSendDelay: params.undoSendDelay
        )
        dependencies
            .sendMessage
            .execute(params: params) { sendMessageResult in
                switch sendMessageResult {
                case .failure(let error):
                    SystemLogger.log(message: "\(error)", category: .sendMessage, isError: true)
                    completion(.failure(error))
                case .success:
                    SystemLogger.log(message: "Message sent", category: .sendMessage)
                    completion(.success(Void()))
                }
            }
    }
}

// MARK: After sending methods

extension SendMessageTask {

    /// Logic related to user alerts/notifications or queue flow
    private func afterSendingMessageSuccess(message: MessageEntity, params: Params) {
        unscheduleNotification(messageID: message.messageID)
        dependencies.notificationCenter.post(name: .sendMessageTaskSuccess, object: nil)
        #if !APP_EXTENSION
        updateScheduledMessagesFolderIfNeeded(message: message, params: params)
        showUndoBannerIfNeeded(message: message, params: params)
        #endif
    }

    /// Logic related to user alerts/notifications, error management or queue flow
    private func afterSendingMessageFailure(message: MessageEntity, error: Error) -> Error? {
        SystemLogger.log(message: "sending finished with error: \(error)", category: .sendMessage, isError: true)
        var resultingError: Error? = error
        switch error {
        case let apiError as ResponseError:
            resultingError = handleApiError(message: message, error: apiError)
        default:
            notifySendMessageError(error, message: message)
        }
        return resultingError
    }

    private func handleApiError(message: MessageEntity, error: ResponseError) -> Error? {
        var hasErrorBeenProcessed: Bool = false
        if error.responseCode == APIErrorCode.humanVerificationRequired {
            dependencies.queueManager.isRequiredHumanCheck = true
            notifySendMessageError(error, message: message)
        } else if error.responseCode == APIErrorCode.alreadyExist {
            hasErrorBeenProcessed = true
            unscheduleNotification(messageID: message.messageID)
        } else if error.responseCode == APIErrorCode.invalidRequirements {
            hasErrorBeenProcessed = true
            unscheduleNotification(messageID: message.messageID)
            dependencies.notificationCenter.post(name: .showScheduleSendUnavailable, object: nil)
        } else if error.responseCode == PGPTypeErrorCode.emailAddressFailedValidation.rawValue {
            dependencies.notificationCenter.post(name: .messageSendFailAddressValidationIncorrect, object: nil)
            notifySendMessageError(error, message: message)
        } else {
            notifySendMessageError(error, message: message)
        }
        return hasErrorBeenProcessed ? nil : error
    }

    private func notifySendMessageError(_ error: Error?, message: MessageEntity, suggestSendMessageAgain: Bool = true) {
        let messagePrefix = suggestSendMessageAgain
        ? LocalString._messages_sending_failed_try_again
        : LocalString._message_sent_failed_desc
        let errorMessage: String
        if let error = error {
            errorMessage = messagePrefix + "\n" + error.localizedDescription
        } else {
            errorMessage = messagePrefix
        }
        let userInfo = [Notification.UserInfoKey.errorMessage: errorMessage]
        dependencies.notificationCenter.post(name: .sendMessageTaskFail, object: nil, userInfo: userInfo)

        dependencies
            .localNotificationService
            .scheduleMessageSendingFailedNotification(.init(
                messageID: message.messageID.rawValue,
                error: errorMessage,
                timeInterval: 1.0,
                subtitle: message.title
            ))
    }

    private func updateScheduledMessagesFolderIfNeeded(message: MessageEntity, params: Params) {
        guard let deliveryTime = params.deliveryTime else {
            return
        }
        dependencies.eventsFetching.fetchEvents(
            byLabel: Message.Location.scheduled.labelID,
            notificationMessageID: nil
        ) { [unowned self] _ in
            dependencies.notificationCenter.post(
                name: .scheduledMessageSucceed,
                object: (message.messageID, deliveryTime, params.userID)
            )
        }
    }

    private func showUndoBannerIfNeeded(message: MessageEntity, params: Params) {
        guard params.deliveryTime == nil else {
            return
        }
        dependencies.undoActionManager.showUndoSendBanner(for: message.messageID)
    }

    private func unscheduleNotification(messageID: MessageID) {
        dependencies
            .localNotificationService
            .unscheduleMessageSendingFailedNotification(.init(messageID: messageID.rawValue))
    }
}

// MARK: Dependencies and Params

extension SendMessageTask {

    struct Dependencies {
        let isUserAuthenticated: (UserID) -> Bool
        let messageDataService: MessageDataServiceProtocol
        let fetchMessageDetail: FetchMessageDetailUseCase
        let sendMessage: SendMessageUseCase
        let localNotificationService: LocalNotificationService
        let eventsFetching: EventsFetching
        let undoActionManager: UndoActionManagerProtocol
        let queueManager: QueueManager
        let notificationCenter: NotificationCenter

        init(
            isUserAuthenticated: @escaping (UserID) -> Bool,
            messageDataService: MessageDataServiceProtocol,
            fetchMessageDetail: FetchMessageDetailUseCase,
            sendMessage: SendMessageUseCase,
            localNotificationService: LocalNotificationService,
            eventsFetching: EventsFetching,
            undoActionManager: UndoActionManagerProtocol,
            queueManager: QueueManager = sharedServices.get(by: QueueManager.self),
            notificationCenter: NotificationCenter = NotificationCenter.default
        ) {
            self.isUserAuthenticated = isUserAuthenticated
            self.messageDataService = messageDataService
            self.fetchMessageDetail = fetchMessageDetail
            self.sendMessage = sendMessage
            self.localNotificationService = localNotificationService
            self.eventsFetching = eventsFetching
            self.undoActionManager = undoActionManager
            self.queueManager = queueManager
            self.notificationCenter = notificationCenter
        }
    }

    struct Params {
        let messageURI: String
        let deliveryTime: Date?
        let undoSendDelay: Int
        let userID: UserID
    }
}

enum SendMessageTaskError: Error {
    case noMessageFoundForURI
}
