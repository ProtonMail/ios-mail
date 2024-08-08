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
import ProtonCoreNetworking
import ProtonCoreServices

protocol UploadDraftUseCase {
    func execute(messageObjectID: String) async throws
}

final class UploadDraft: UploadDraftUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// - Parameters:
    ///   - objectID: Message object ID
    func execute(messageObjectID: String) async throws {
        do {
            guard let messageData = dependencies.messageDataService.getMessageSendingData(for: messageObjectID) else {
                throw UploadDraftError.messageNotFoundForURI(messageObjectID)
            }
            let jsonResponse = try await sendUploadRequest(messageData: messageData)
            try apply(response: jsonResponse, to: messageObjectID)
        } catch {
            if let responseError = error as? ResponseError,
               let underlyingError = responseError.underlyingError {
                if underlyingError.code != APIErrorCode.updateDraftHasBeenSent {
                    if underlyingError.localizedDescription.isEmpty {
                        let code = underlyingError.bestShotAtReasonableErrorCode
                        PMAssertionFailure("Attempting to display error with empty description, code \(code)")
                    } else {
                        SystemLogger.log(error: error, category: .emptyAlert)
                    }
                    await NSError.alertSavingDraftError(details: underlyingError.localizedDescription)
                }

                if underlyingError.isStorageExceeded {
                    dependencies.messageDataService.deleteMessage(objectID: messageObjectID)
                }
            } else if error is UploadDraftError {
                SystemLogger.log(message: "UploadDraftError: \(error)", isError: true)
            } else {
                if error.localizedDescription.isEmpty {
                    let code = error.bestShotAtReasonableErrorCode
                    PMAssertionFailure("Attempting to display error with empty description, code \(code)")
                } else {
                    SystemLogger.log(error: error, category: .emptyAlert)
                }
                await NSError.alertSavingDraftError(details: error.localizedDescription)
            }
            throw error
        }
    }

    private func sendUploadRequest(messageData: MessageSendingData) async throws -> JSONDictionary {
        let messageDataService = dependencies.messageDataService
        let addressID: AddressID = messageData.message.addressID
        let address = messageDataService.userAddress(of: addressID) ??
        messageData.cachedSenderAddress ??
        messageData.defaultSenderAddress
        let message = messageData.message

        let request: Request
        if message.isDetailDownloaded && UUID(uuidString: message.messageID.rawValue) == nil {
            request = UpdateDraftRequest(
                message: message,
                fromAddr: address,
                authCredential: messageData.cachedAuthCredential
            )
        } else {
            request = CreateDraftRequest(message: message, fromAddr: address)
        }
        let response = try await dependencies.apiService.perform(request: request)
        return response.1
    }

    private func apply(response: JSONDictionary, to messageObjectID: String) throws {
        let coreDataService = dependencies.coreDataService
        try coreDataService.performAndWaitOnRootSavingContext { context in
            guard var messageResponse = response["Message"] as? [String: Any],
                  let messageID = messageResponse["ID"] as? String, !messageID.isEmpty else {
                throw NSError.unableToParseResponse(nil)
            }

            guard let objectID = coreDataService.managedObjectIDForURIRepresentation(messageObjectID),
                  let message = context.find(with: objectID) as? Message else {
                // this message is deleted, don't handle response
                return
            }
            message.messageID = messageID
            message.isDetailDownloaded = true

            if let conversationID = messageResponse["ConversationID"] as? String {
                message.conversationID = conversationID
            }
            if let subject = messageResponse["Subject"] as? String {
                message.title = subject
            }
            if let timeValue = messageResponse["Time"] {
                // String is legacy
                if let timeString = timeValue as? NSString {
                    let time = timeString.doubleValue as TimeInterval
                    if time != 0 {
                        message.time = time.asDate()
                    }
                } else if let dateNumber = timeValue as? NSNumber {
                    let time = dateNumber.doubleValue as TimeInterval
                    if time != 0 {
                        message.time = time.asDate()
                    }
                }
            }
            messageResponse.addAttachmentOrderField()
            self.updateAttachment(from: messageResponse, to: message)
            _ = context.saveUpstreamIfNeeded()
        }
    }

    private func updateAttachment(from response: JSONDictionary, to message: Message) {
        guard let attachmentInfo = response["Attachments"] as? [[String: Any]] else { return }
        let attachments = message
            .mutableSetValue(forKey: "attachments")
            .compactMap { $0 as? Attachment }
        for attachment in attachments {
            guard
                let updateInfo = attachmentInfo.first(where: { $0["KeyPackets"] as? String == attachment.keyPacket })
            else { continue }
            if let attachmentID = updateInfo["ID"] as? String {
                attachment.attachmentID = attachmentID
            }
            if let order = updateInfo["Order"] as? Int {
                attachment.order = Int32(order)
            }
            attachment.isTemp = false
            attachment.keyChanged = false
        }
    }
}

extension UploadDraft {

    struct Dependencies {
        let apiService: APIService
        let coreDataService: CoreDataContextProviderProtocol
        let messageDataService: MessageDataServiceProtocol

        init(
            apiService: APIService,
            coreDataService: CoreDataContextProviderProtocol,
            messageDataService: MessageDataServiceProtocol
        ) {
            self.apiService = apiService
            self.coreDataService = coreDataService
            self.messageDataService = messageDataService
        }
    }

    enum UploadDraftError: LocalizedError, Equatable {
        case messageNotFoundForURI(String)

        var errorDescription: String? {
            switch self {
            case .messageNotFoundForURI(let uri):
                return "Message not found for URI: \(uri)"
            }
        }
    }
}
