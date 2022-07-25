//
//  MessageDataService+Builder.swift
//  Proton Mail - Created on 4/12/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Crypto
import Foundation
import OpenPGP
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Hash
import ProtonCore_Services
import ProtonCore_Hash

extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            return nil
        }
    }
}

extension String {
    var html2AttributedString: NSAttributedString? {
        return Data(utf8).html2AttributedString
    }

    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

final class PreContact {
    let email: String
    let firstPgpKey: Data?
    let pgpKeys: [Data]
    let sign: Bool
    let encrypt: Bool
    let mime: Bool
    let plainText: Bool
    let isContactSignatureVerified: Bool
    let scheme: String?
    let mimeType: String?

    init(email: String,
         pubKey: Data?,
         pubKeys: [Data],
         sign: Bool,
         encrypt: Bool,
         mime: Bool,
         plainText: Bool,
         isContactSignatureVerified: Bool,
         scheme: String?,
         mimeType: String?
    ) {
        self.email = email
        self.firstPgpKey = pubKey
        self.pgpKeys = pubKeys
        self.sign = sign
        self.encrypt = encrypt
        self.mime = mime
        self.plainText = plainText
        self.isContactSignatureVerified = isContactSignatureVerified
        self.scheme = scheme
        self.mimeType = mimeType
    }
}

extension Array where Element == PreContact {
    func find(email: String) -> PreContact? {
        for contact in self where contact.email == email {
            return contact
        }
        return nil
    }
}

final class PreAddress: NSObject {
    let email: String
    let recipientType: KeysResponse.RecipientType
    let isEO: Bool
    let pubKey: String?
    let pgpKey: Data?
    let mime: Bool
    let sign: Bool
    let pgpencrypt: Bool
    let plainText: Bool

    init(email: String,
         pubKey: String?,
         pgpKey: Data?,
         recipientType: KeysResponse.RecipientType,
         isEO: Bool,
         mime: Bool,
         sign: Bool,
         pgpencrypt: Bool,
         plainText: Bool) {
        self.email = email
        self.recipientType = recipientType
        self.isEO = isEO
        self.pubKey = pubKey
        self.pgpKey = pgpKey
        self.mime = mime
        self.sign = sign
        self.pgpencrypt = pgpencrypt
        self.plainText = plainText
    }
}

final class PreAttachment {
    /// attachment id
    let attachmentId: String
    /// clear session key
    let session: Data
    let algo: String
    let att: Attachment

    /// initial
    ///
    /// - Parameters:
    ///   - id: att id
    ///   - key: clear encrypted attachment session key
    init(id: String, session: Data, algo: String, att: Attachment) {
        self.attachmentId = id
        self.session = session
        self.algo = algo
        self.att = att
    }
}
