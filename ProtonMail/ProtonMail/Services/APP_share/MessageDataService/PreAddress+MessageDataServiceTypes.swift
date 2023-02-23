// swiftlint:disable:this file_name
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

import Foundation
import GoLibs
import OpenPGP
import PromiseKit
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Hash
import ProtonCore_Services

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
    let pgpKeys: [Data]
    let sign: Bool
    let encrypt: Bool
    let scheme: String?
    let mimeType: String?

    init(email: String,
         pubKeys: [Data],
         sign: Bool,
         encrypt: Bool,
         scheme: String?,
         mimeType: String?
    ) {
        self.email = email
        self.pgpKeys = pubKeys
        self.sign = sign
        self.encrypt = encrypt
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

final class PreAttachment {
    /// attachment id
    let attachmentId: String
    /// clear session key
    let session: Data
    let algo: Algorithm
    let att: AttachmentEntity

    /// initial
    ///
    /// - Parameters:
    ///   - id: att id
    ///   - key: clear encrypted attachment session key
    init(id: String, session: Data, algo: Algorithm, att: AttachmentEntity) {
        self.attachmentId = id
        self.session = session
        self.algo = algo
        self.att = att
    }
}
