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

enum SendPreferencesHelper {
    static func getSendPreferences(encryptionPreferences: EncryptionPreferences,
                                   isMessageHavingPWD: Bool) -> SendPreferences {
        let isEncryptedOutside = isMessageHavingPWD
        let newEncrypt = encryptionPreferences.encrypt || isEncryptedOutside
        let newSign = isEncryptedOutside ? false : encryptionPreferences.sign

        let (pgpScheme, mimeType) = getPGPSchemeAndMimeType(encryptionPreferences: encryptionPreferences,
                                                            isMessageHavingPWD: isMessageHavingPWD)
        return .init(encrypt: newEncrypt,
                     sign: newSign,
                     pgpScheme: pgpScheme,
                     mimeType: mimeType,
                     publicKeys: encryptionPreferences.sendKey,
                     isPublicKeyPinned: encryptionPreferences.isSendKeyPinned,
                     hasApiKeys: encryptionPreferences.hasApiKeys,
                     hasPinnedKeys: encryptionPreferences.hasPinnedKeys,
                     error: encryptionPreferences.error)
    }

    static func getPGPSchemeAndMimeType(encryptionPreferences: EncryptionPreferences,
                                        isMessageHavingPWD: Bool) -> (PGPScheme, SendMIMEType) {
        let pgpScheme = getPGPScheme(isInternal: encryptionPreferences.isInternal,
                                     schemeString: encryptionPreferences.scheme ?? "",
                                     encrypt: encryptionPreferences.encrypt,
                                     sign: encryptionPreferences.sign,
                                     isPasswordProtected: isMessageHavingPWD,
                                     hasPublicKeys: encryptionPreferences.sendKey != nil)
        if encryptionPreferences.sign, [PGPScheme.pgpInline, PGPScheme.pgpMIME].contains(pgpScheme) {
            let enforceMIMEType: SendMIMEType = pgpScheme == .pgpInline ? .plainText : .mime
            return (pgpScheme, enforceMIMEType)
        }

        if let mime = encryptionPreferences.mimeType, let mimeType = SendMIMEType(rawValue: mime) {
            return (pgpScheme, mimeType)
        } else {
            return (pgpScheme, .mime)
        }
    }

    /**
     * Logic for determining the PGP scheme to be used when sending to an email address.
     * The API expects a package type.
     */
    static func getPGPScheme(isInternal: Bool,
                             schemeString: String,
                             encrypt: Bool,
                             sign: Bool,
                             isPasswordProtected: Bool,
                             hasPublicKeys: Bool) -> PGPScheme {
        if isInternal {
            return .proton
        }
        if isPasswordProtected && encrypt == false {
            return .encryptedToOutside
        }
        if sign {
            if hasPublicKeys {
                return schemeString == MessageEncryptionIconHelper.ContentEncryptionType
                    .pgpInline.rawValue ? .pgpInline : .pgpMIME
            } else {
                return .cleartextMIME
            }
        }
        return .cleartextInline
    }
}
