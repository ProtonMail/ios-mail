//
//  KeysAPI.swift
//  Proton Mail - Created on 11/11/16.
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

import PromiseKit
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreServices

struct KeysAPI {
    static let path: String = "/keys"
}

final class UserEmailPubKeys: Request {
    let email: String

    init(email: String, authCredential: AuthCredential? = nil) {
        self.email = email
        self.auth = authCredential
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = ["Email": self.email]
        return out
    }

    var path: String {
        return KeysAPI.path
    }

    // custom auth credentical
    let auth: AuthCredential?
    var authCredential: AuthCredential? {
        get {
            return self.auth
        }
    }
}

struct KeyResponse {
    let flags: Key.Flags
    let publicKey: String
}

final class KeysResponse: Response {
    enum RecipientType: Int {
        case `internal` = 1
        case external = 2
    }
    var recipientType: RecipientType = .internal
    var keys: [KeyResponse] = [KeyResponse]()

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        let rawRecipientType = response["RecipientType"] as? Int ?? 0
        self.recipientType = RecipientType(rawValue: rawRecipientType) ?? .external

        if let keyRes = response["Keys"] as? [[String: Any]] {
            for keyDict in keyRes {
                let rawFlags = keyDict["Flags"] as? Int ?? 0
                let flags = Key.Flags(rawValue: rawFlags)

                guard let publicKey = keyDict["PublicKey"] as? String else {
                    continue
                }

                self.keys.append(KeyResponse(flags: flags, publicKey: publicKey))
            }
        }
        return true
    }

    var nonObsoletePublicKeys: [ArmoredKey] {
        keys
            .filter { $0.flags.contains(.notObsolete) }
            .map { ArmoredKey(value: $0.publicKey)}
    }
}

/// message packages
final class PasswordAuth: Package {

    let AuthVersion: Int = 4
    let ModulusID: String // encrypted id
    let salt: String // base64 encoded
    let verifer: String // base64 encoded

    init(modulus_id: String, salt: String, verifer: String) {
        self.ModulusID = modulus_id
        self.salt = salt
        self.verifer = verifer
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = [
            "Version": self.AuthVersion,
            "ModulusID": self.ModulusID,
            "Salt": self.salt,
            "Verifier": self.verifer
        ]
        return out
    }
}

// MARK: active a key when Activation is not null --- Response
final class ActivateKey: Request {
    let addressID: String
    let privateKey: String
    let signedKeyList: [String: Any]

    init(addrID: String, privKey: String, signedKL: [String: Any]) {
        self.addressID = addrID
        self.privateKey = privKey
        self.signedKeyList = signedKL
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = [
            "PrivateKey": self.privateKey,
            "SignedKeyList": self.signedKeyList
        ]
        return out
    }

    var method: HTTPMethod {
        return .put
    }

    var path: String {
        return KeysAPI.path + "/" + addressID + "/activate"
    }

    // custom auth credentical
    var auth: AuthCredential?
    var authCredential: AuthCredential? {
        get {
            return self.auth
        }
    }
}
