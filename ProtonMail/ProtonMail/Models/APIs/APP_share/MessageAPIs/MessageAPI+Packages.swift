//
//  MessageAPI+Packages.swift
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
import ProtonCore_Networking

// message attachment key package
final class AttachmentPackage {
    let ID: String
    let encodedKeyPacket: String
    init(attachmentID: String, attachmentKey: String!) {
        self.ID = attachmentID
        self.encodedKeyPacket = attachmentKey
    }
}

// message attachment key package for clear text
final class ClearAttachmentPackage {
    /// attachment id
    let ID: String
    /// based64 encoded session key
    let encodedSession: String
    let algo: String // default is "aes256"
    init(attachmentID: String, encodedSession: String, algo: String) {
        self.ID = attachmentID
        self.encodedSession = encodedSession
        self.algo = algo
    }
}

// message attachment key package for clear text
final class ClearBodyPackage {
    /// based64 encoded session key
    let key: String
    let algo: String // default is "aes256"
    init(key: String, algo: String) {
        self.key = key
        self.algo = algo
    }
}

final class EOAddressPackage: AddressPackage {
    let token: String
    let encToken: String
    let auth: PasswordAuth
    let passwordHint: String?

    init(token: String, encToken: String,
         auth: PasswordAuth, passwordHint: String?,
         email: String,
         bodyKeyPacket: String,
         plainText: Bool,
         attachmentPackages: [AttachmentPackage] = [AttachmentPackage](),
         scheme: PGPScheme = .proton,
         sign: Int = 0) {
        self.token = token
        self.encToken = encToken
        self.auth = auth
        self.passwordHint = passwordHint

        super.init(email: email,
                   bodyKeyPacket: bodyKeyPacket,
                   scheme: scheme,
                   plainText: plainText,
                   attachmentPackages: attachmentPackages,
                   sign: sign)
    }

    override var parameters: [String: Any]? {
        var out = super.parameters ?? [String: Any]()
        out["Token"] = self.token
        out["EncToken"] = self.encToken
        out["Auth"] = self.auth.parameters
        if let hit = self.passwordHint {
            out["PasswordHint"] = hit
        }
        return out
    }
}

class AddressPackage: AddressPackageBase {
    let bodyKeyPacket: String
    let attachmentPackages: [AttachmentPackage]

    init(email: String,
         bodyKeyPacket: String,
         scheme: PGPScheme,
         plainText: Bool,
         attachmentPackages: [AttachmentPackage] = [AttachmentPackage](),
         sign: Int = 0) {
        self.bodyKeyPacket = bodyKeyPacket
        self.attachmentPackages = attachmentPackages
        super.init(email: email, scheme: scheme, sign: sign, plainText: plainText)
    }

    override var parameters: [String: Any]? {
        var out = super.parameters ?? [String: Any]()
        out["BodyKeyPacket"] = self.bodyKeyPacket
        // change to == id : packet
        if attachmentPackages.count > 0 {
            var atts = [String: Any]()
            for attPacket in attachmentPackages {
                atts[attPacket.ID] = attPacket.encodedKeyPacket
            }
            out["AttachmentKeyPackets"] = atts
        }

        return out
    }
}

class MimeAddressPackage: AddressPackageBase {
    let bodyKeyPacket: String
    init(email: String,
         bodyKeyPacket: String,
         scheme: PGPScheme,
         plainText: Bool) {
        self.bodyKeyPacket = bodyKeyPacket
        super.init(email: email, scheme: scheme, sign: -1, plainText: plainText)
    }

    override var parameters: [String: Any]? {
        var out = super.parameters ?? [String: Any]()
        out["BodyKeyPacket"] = self.bodyKeyPacket
        return out
    }
}

class AddressPackageBase: Package {
    let scheme: PGPScheme
    let sign: Int // 0 or 1
    let email: String
    let plainText: Bool

    init(email: String, scheme: PGPScheme, sign: Int, plainText: Bool) {
        self.scheme = scheme
        self.sign = sign
        self.email = email
        self.plainText = plainText
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [
            "Type": scheme.rawValue
        ]
        if sign > -1 {
            out["Signature"] = sign
        }
        return out
    }
}
