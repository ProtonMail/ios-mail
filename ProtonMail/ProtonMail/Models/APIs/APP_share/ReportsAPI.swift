//
//  BugsAPI.swift
//  Proton Mail - Created on 7/21/15.
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
import ProtonCoreNetworking

/**
 [Proton Mail Reports API]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_reports.md "Report a problem"
 
 Reports API
 - Doc: [Proton Mail Reports API]
 */
struct ReportsAPI {
    static let path: String = "/reports"
}

// MARK: Get messages part -- Response
/// Report a problem [POST]
final class ReportPhishing: Request {
    enum ParameterKeys: String {
        case messageID = "MessageID"
        case mimeType = "MIMEType"
        case body = "Body"
    }

    let msgID: String
    let mimeType: String
    let body: String

    init(msgID: String, mimeType: String, body: String) {
        self.msgID = msgID
        self.mimeType = mimeType
        self.body = body
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = [
            ParameterKeys.messageID.rawValue: self.msgID,
            ParameterKeys.mimeType.rawValue: self.mimeType,
            ParameterKeys.body.rawValue: self.body
        ]
        return out
    }

    static var defaultMethod: HTTPMethod { .post }
    var method: HTTPMethod { Self.defaultMethod }

    static var defaultPath: String { ReportsAPI.path + "/phishing" }
    var path: String { Self.defaultPath }
}
