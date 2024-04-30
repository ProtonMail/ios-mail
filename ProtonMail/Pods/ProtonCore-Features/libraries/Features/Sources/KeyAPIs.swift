//
//  KeyAPIs.swift
//  ProtonCore-Features - Created on 08.03.2021.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreKeyManager
import ProtonCoreNetworking
import ProtonCoreServices

extension Array where Element: Request {
    func performConcurrentlyAndWaitForResults<T: Response>(api: APIService, response: T.Type) -> [Result<T, Error>] {

        assert(Thread.isMainThread == false, "This is a blocking call, should never be called from the main thread")

        let group = DispatchGroup()

        var results: [(UUID, Result<T, Error>)] = []
        let requests = map { (UUID(), $0) }
        let uuids = requests.map(\.0)
        requests.forEach { uuid, request in
            let responseObject: T = T()
            group.enter()
            api.perform(request: request, response: responseObject) { (_, response: T) in
                if let responseError = response.error {
                    results.append((uuid, .failure(responseError)))
                } else {
                    results.append((uuid, .success(response)))
                }
                group.leave()
            }
        }
        group.wait()

        return results.sorted { lhs, rhs in
            guard let lhIndex = uuids.firstIndex(of: lhs.0), let rhIndex = uuids.firstIndex(of: rhs.0) else {
                assertionFailure("Should never happen — the UUIDs associated with requests must not be changed")
                return true
            }
            return lhIndex < rhIndex
        }.map { $0.1 }
    }
}

// Keys API
struct KeysAPI {
    static let path: String = "/keys"
}

/// KeysResponse
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
    var authCredential: AuthCredential? { auth }
}

final class KeyResponse {
    // TODO:: change to bitmap later
    var flags: Int = 0 // bitmap: 1 = can be used to verify, 2 = can be used to encrypt
    var publicKey: String?

    init(flags: Int, pubkey: String?) {
        self.flags = flags
        self.publicKey = pubkey
    }
}

final class KeysResponse: Response {
    var recipientType: Int = 1 // 1 internal 2 external
    var mimeType: String?
    var keys: [KeyResponse] = [KeyResponse]()
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.recipientType = response["RecipientType"] as? Int ?? 1
        self.mimeType = response["MIMEType"] as? String

        if let keyRes = response["Keys"] as? [[String: Any]] {
            for keyDict in keyRes {
                let flags = keyDict["Flags"] as? Int ?? 0
                let pubKey = keyDict["PublicKey"] as? String
                self.keys.append(KeyResponse(flags: flags, pubkey: pubKey))
            }
        }
        return true
    }

    func firstKey () -> String? {
        for k in keys {
            if k.flags == 2 || k.flags == 3 {
                return k.publicKey
            }
        }
        return nil
    }

    // TODO:: change to filter later.
    func getCompromisedKeys() -> Data?  {
        var pubKeys: Data?
        for k in keys where k.flags == 0 {
            if pubKeys == nil {
                pubKeys = Data()
            }
            if let p = k.publicKey {
                var error: NSError?
                if let data = CryptoGo.ArmorUnarmor(p, &error) {
                    if error == nil && data.count > 0 {
                        pubKeys?.append(data)
                    }
                }
            }
        }
        return pubKeys
    }

    func getVerifyKeys() -> Data? {
        var pubKeys: Data?
        for k in keys {
            if k.flags == 1 || k.flags == 3 {
                if pubKeys == nil {
                    pubKeys = Data()
                }
                if let p = k.publicKey {
                    var error: NSError?
                    if let data = CryptoGo.ArmorUnarmor(p, &error) {
                        if error == nil && data.count > 0 {
                            pubKeys?.append(data)
                        }
                    }
                }
            }
        }
        return pubKeys
    }
}
