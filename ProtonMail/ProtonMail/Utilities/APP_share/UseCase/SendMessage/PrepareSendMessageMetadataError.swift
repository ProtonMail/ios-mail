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

/// Errors that can be returned by the SendMessageMetadata use case.
enum PrepareSendMessageMetadataError: String, Error {
    case messageIdEmptyForURI = "No message found for URI"
    case noSenderAddressFound = "No sender address found"
    case noSenderAddressKeyFound = "No sender address key found"
    case splitMessageFail = "Split message fail"
    case splitMessageKeyPacketFail = "Split message key packet fail"
    case splitMessageDataPacketFail = "Split message data packet fail"
    case bodySessionKeyFail = "Body session key fail"
    case decryptBodyFail = "Decrypt body fail"
}

extension PrepareSendMessageMetadataError: LocalizedError {

    var errorDescription: String? {
        "PrepareSendMessageMetadataError: \(rawValue)"
    }
}
