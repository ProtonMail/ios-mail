//
//  BugDataService.swift
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

class BugDataService: Service {
    private let apiService: APIService
    init(api: APIService) {
        self.apiService = api
    }
    func reportPhishing(messageID: MessageID, messageBody: String, completion: ((NSError?) -> Void)?) {
        let route = ReportPhishing(msgID: messageID.rawValue, mimeType: "text/html", body: messageBody)
        self.apiService.exec(route: route, responseObject: VoidResponse()) { res in
            completion?(res.error?.toNSError)
        }
    }

    func reportBug(_ bug: String,
                          username: String,
                          email: String,
                          lastReceivedPush: String,
                          reachabilityStatus: String,
                          completion: ((NSError?) -> Void)?) {
        let systemVersion = UIDevice.current.systemVersion
        let model = "iOS - \(UIDevice.current.model)"
        let mainBundle = Bundle.main
        let username = username
        let useremail = email
        let route = BugReportRequest(os: model,
                                     osVersion: "\(systemVersion)",
                                     clientVersion: mainBundle.appVersion,
                                     title: "Proton Mail App bug report",
                                     desc: bug,
                                     userName: username,
                                     email: useremail,
                                     lastReceivedPush: lastReceivedPush,
                                     reachabilityStatus: reachabilityStatus)
        self.apiService.exec(route: route, responseObject: VoidResponse()) { res in
            completion?(res.error?.toNSError)
        }
    }
}
