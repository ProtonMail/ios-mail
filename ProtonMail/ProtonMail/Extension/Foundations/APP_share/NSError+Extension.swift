//
//  NSError+Extension.swift
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
import ProtonCore_Services

extension NSError {

    convenience init(domain: String,
                     code: Int,
                     localizedDescription: String,
                     localizedFailureReason: String? = nil,
                     localizedRecoverySuggestion: String? = nil) {
        var userInfo = [NSLocalizedDescriptionKey: localizedDescription]

        if let localizedFailureReason = localizedFailureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = localizedFailureReason
        }

        if let localizedRecoverySuggestion = localizedRecoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = localizedRecoverySuggestion
        }

        self.init(domain: domain, code: code, userInfo: userInfo)
    }

    class func protonMailError(_ code: Int,
                               localizedDescription: String,
                               localizedFailureReason: String? = nil,
                               localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(domain: protonMailErrorDomain(),
                       code: code,
                       localizedDescription: localizedDescription,
                       localizedFailureReason: localizedFailureReason,
                       localizedRecoverySuggestion: localizedRecoverySuggestion)
    }

    class func protonMailErrorDomain(_ subdomain: String? = nil) -> String {
        var domain = Bundle.main.bundleIdentifier ?? "ch.protonmail"

        if let subdomain = subdomain {
            domain += ".\(subdomain)"
        }
        return domain
    }

    func isInternetError() -> Bool {
        var isInternetIssue = false
        let identifier = "com.alamofire.serialization.response.error.response"
        if self.userInfo[identifier] as? HTTPURLResponse != nil {
        } else {
            if self.code == -1_009 ||
                self.code == -1_004 ||
                self.code == -1_001 {
                isInternetIssue = true
            }
        }
        return isInternetIssue
    }

    var isBadVersionError: Bool {
        // These two error codes are badAppVersion and badApiVersion
        // But the ProtonCore doesn't have it
        // it should use library constant after library update
        return self.code == 5_003 || self.code == 5_005
    }

    var isStorageExceeded: Bool {
        return self.code == 2_011
    }
}
