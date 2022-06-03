//
//  APIService+MessagesExtension.swift
//  Proton Mail
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
import ProtonCore_Services

// TODO:: this file need to be removed
private struct MessagePath {
    static let base = "/\(Constants.App.API_PREFIXED)/messages"
}

// TODO :: all the request post put ... all could abstract a body layer, after change the request only need the url and request object.
/// Messages extension
extension APIService {

    func GET( _ api : Request, authCredential: AuthCredential? = nil, priority: String? = nil, completion: CompletionBlock?) {
        var headers = api.header
        if priority != nil {
            headers["priority"] = priority
        }
        //print("GET REQUEST: path:\(api.path), parameters: \(api.parameters), headers: \(headers)")
        self.request(method: .get,
                     path: api.path,
                     parameters: api.parameters,
                     headers: api.header,
                     authenticated: api.isAuth,
                     autoRetry: api.autoRetry,
                     customAuthCredential: api.authCredential,
                     completion: completion)
    }

    func messageDetail(messageID: MessageID, priority: String? = nil, completion: @escaping CompletionBlock) {
        let path = MessagePath.base + "/\(messageID.rawValue)"
        var headers: [String:Any] = [:]
        if priority != nil {
            headers["priority"] = priority
        }
        self.request(method: .get,
                     path: path,
                     parameters: nil,
                     headers: headers,
                     authenticated: true,
                     autoRetry: true,
                     customAuthCredential: nil,
                     completion: completion)
    }
}
