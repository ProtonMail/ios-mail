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
import ProtonCore_Crypto
@testable import ProtonMail
import ProtonCore_TestingToolkit

final class MockPrepareSendRequest: NewUseCase<SendMessageRequest, PrepareSendRequest.Params> {

    private lazy var dummySendMessageRequest: SendMessageRequest = {
        let messageID = UUID().uuidString
        let expirationTime = Int.random(in: 1...5)
        let delaySecond = Int.random(in: 1...9)
        let deliveryTime = Date()
        let messagePackage = AddressPackage(
            email: "test@pm.me",
            bodyKeyPacket: "test body packet",
            scheme: .pgpMIME,
            plainText: false
        )
        let algo = Algorithm.AES256
        let clearBody = ClearBodyPackage(key: "clear body key", algo: algo)
        let attachmentID = UUID().uuidString
        let attachment = ClearAttachmentPackage(
            attachmentID: attachmentID,
            encodedSession: "encoded session",
            algo: algo
        )
        let clearMIMEBody = ClearBodyPackage(key: "mime body key", algo: algo)
        return SendMessageRequest(
            messageID: messageID,
            expirationTime: expirationTime,
            delaySeconds: delaySecond,
            messagePackage: [messagePackage],
            body: "This is body",
            clearBody: clearBody,
            clearAtts: [attachment],
            mimeDataPacket: "mime package",
            clearMimeBody: clearMIMEBody,
            plainTextDataPacket: "plain text",
            clearPlainTextBody: nil,
            authCredential: nil,
            deliveryTime: deliveryTime
        )
    }()

    private var successResult: Result<SendMessageRequest, Error> { .success(dummySendMessageRequest) }
    var failureResult: Error?

    @FuncStub(MockPrepareSendRequest.executionBlock) var executionBlock
    override func executionBlock(params: PrepareSendRequest.Params, callback: @escaping Callback) {
        executionBlock(params, callback)
        if let error = failureResult {
            callback(.failure(error))
        } else {
            callback(successResult)
        }
    }
}
