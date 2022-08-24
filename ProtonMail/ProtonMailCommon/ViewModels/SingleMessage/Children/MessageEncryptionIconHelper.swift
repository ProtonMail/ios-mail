// Copyright (c) 2022 Proton AG
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

struct MessageEncryptionIconHelper {
    enum ContentEncryptionType: String, Equatable {
        case none = "none"
        case pgpInline = "pgp-inline"
        case pgpInlinePinned = "pgp-inline-pinned"
        case pgpMIME = "pgp-mime"
        case pgpMIMEPinned = "pgp-mime-pinned"
        case pgpPM = "pgp-pm"
        case pgpPMPinned = "pgp-pm-pinned"
        case pgpEO = "pgp-eo"
        case `internal` = "internal"
        case external = "external"
        case endToEnd = "end-to-end"
        case onCompose = "on-compose"
        case onDelivery = "on-delivery"

        static let internalTypes: [Self] = [.pgpPM, .pgpPMPinned, pgpEO]
        static let pinnedTypes: [Self] = [.pgpPMPinned, .pgpMIMEPinned, .pgpInlinePinned]
    }

    func sentStatusIconInfo(message: MessageEntity,
                            completion: @escaping LockCheckComplete) {
        guard !message.parsedHeaders.isEmpty else {
            completion(nil, PGPType.none.rawValue)
            return
        }

        let mapEncryption = getEncryptionMap(headerValue: message.parsedHeaders)
        let contentEncryptionType = getContentEncryption(headerValue: message.parsedHeaders)

        let encryptions = mapEncryption.compactMap { ContentEncryptionType(rawValue: $0.value) }
        let hasHeaderInfo = !encryptions.isEmpty

        let allPinned = hasHeaderInfo &&
        !encryptions.contains(where: { !ContentEncryptionType.pinnedTypes.contains($0) })
        let allEncrypted = hasHeaderInfo && !encryptions.contains(where: { $0 == .none })

        if allPinned {
            if contentEncryptionType == .endToEnd {
                completion(PGPType.sent_sender_encrypted.lockImage, PGPType.sent_sender_encrypted.rawValue)
            } else {
                completion(PGPType.zero_access_store.lockImage, PGPType.zero_access_store.rawValue)
            }
            return
        }
        if allEncrypted {
            if contentEncryptionType == .endToEnd {
                completion(PGPType.sent_sender_encrypted.lockImage, PGPType.sent_sender_encrypted.rawValue)
            } else {
                completion(PGPType.zero_access_store.lockImage, PGPType.zero_access_store.rawValue)
            }
            return
        }
        completion(PGPType.zero_access_store.lockImage, PGPType.zero_access_store.rawValue)
        return
    }

    func getAuthenticationMap(headerValue: [String: Any]) -> [String: String] {
        return getHeaderMap(headerValue: headerValue, headerKey: MessageHeaderKey.pmRecipientAuthentication)
    }

    func getEncryptionMap(headerValue: [String: Any]) -> [String: String] {
        return getHeaderMap(headerValue: headerValue, headerKey: MessageHeaderKey.pmRecipientEncryption)
    }

    func getOrigin(headerValue: [String: Any]) -> String? {
        return getHeaderValue(headerValue: headerValue, headerKey: MessageHeaderKey.pmOrigin)
    }

    func getContentEncryption(headerValue: [String: Any]) -> ContentEncryptionType {
        guard let value = getHeaderValue(headerValue: headerValue,
                                         headerKey: MessageHeaderKey.pmContentEncryption) else {
            return .none
        }
        return ContentEncryptionType(rawValue: value) ?? .none
    }

    func getHeaderMap(headerValue: [String: Any], headerKey: String) -> [String: String] {
        guard let rawValue = headerValue[headerKey] as? String,
              let normalBody = rawValue.removingPercentEncoding else { return [:] }
        // key1=value1;key2=value2
        var result: [String: String] = [:]
        let components = normalBody.components(separatedBy: ";")
        for component in components {
            // key1=value1
            let pieces = component.components(separatedBy: "=")
            guard pieces.count == 2,
                  let key = pieces.first,
                  let data = pieces.last else { continue }
            result[key] = data
        }
        return result
    }

    func getHeaderValue(headerValue: [String: Any], headerKey: String) -> String? {
        guard let rawValue = headerValue[headerKey] as? String else {
            return nil
        }
        return rawValue
    }
}
