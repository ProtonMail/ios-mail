//
//  ReportsAPI.swift
//  ProtonCore-APIClient - Created on 08/30/2021.
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
import ProtonCore_Networking

public struct ReportBug {
    
    public let os: String // iOS, MacOS
    public let osVersion: String
    public let client: String
    public let clientVersion: String
    public let clientType: Int // 1 = email, 2 = VPN
    public var title: String
    public var description: String
    public let username: String
    public var email: String
    public var country: String
    public var ISP: String
    public var plan: String
    public var files = [URL]() // Param names: File0, File1, File2...
    
    public init(os: String, osVersion: String, client: String, clientVersion: String, clientType: Int, title: String, description: String, username: String, email: String, country: String, ISP: String, plan: String) {
        self.os = os
        self.osVersion = osVersion
        self.client = client
        self.clientVersion = clientVersion
        self.clientType = clientType
        self.title = title
        self.description = description
        self.username = username
        self.email = email
        self.country = country
        self.ISP = ISP
        self.plan = plan
    }
    
    public var canBeSent: Bool {
        return !description.isEmpty && !email.isEmpty
    }
}

public struct ReportsBugsResponse: APIDecodableResponse {
    let code: Int
}

public final class ReportsBugs: Request {

    public let bug: ReportBug
    
    public init( _ bug: ReportBug) {
        self.bug = bug
    }

    public var path: String {
        return "/reports/bug"
    }

    public var method: HTTPMethod {
        return .post
    }

    public var parameters: [String: Any]? {
        return [
            "OS": bug.os,
            "OSVersion": bug.osVersion,
            "Client": bug.client,
            "ClientVersion": bug.clientVersion,
            "ClientType": String(bug.clientType),
            "Title": bug.title,
            "Description": bug.description,
            "Username": bug.username,
            "Email": bug.email,
            "Country": bug.country,
            "ISP": bug.ISP,
            "Plan": bug.plan
        ]
    }
    
    var auth: AuthCredential?
    public var authCredential: AuthCredential? {
        return self.auth
    }
}
