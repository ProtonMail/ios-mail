// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct Constants {
    static var AppGroup: String {
#if Enterprise
        return "group.com.protonmail.protonmail"
#else
        return "group.ch.protonmail.protonmail"
#endif
    }

    enum App {
        static let SpaceWarningThresholdDouble: Double = 90
        // 3 is v4 carousel
        // 4 is rebranding carousel
        static let TourVersion : Int                   = 4

        static var appDomain: String { BackendConfiguration.shared.environment.appDomain }
        static var URL_HOST: String { BackendConfiguration.shared.environment.apiDomain }
        static var API_PATH: String { BackendConfiguration.shared.environment.apiPath }
        static let DOH_ENABLE: Bool = true

        static let API_PREFIXED = "mail/v4"
        static func apiHost() -> String {
            if let apiURLOverrideString = UserDefaults.standard.string(forKey: "ch.protonmail.protonmail.APIURLOverride"), let apiURLOverride = URL(string: apiURLOverrideString) {
                return apiURLOverride.absoluteString
            }
            return "https://\(URL_HOST)"
        }

        static func captchaHost() -> String {
            if URL_HOST.starts(with: "api.") {
                return "https://\(URL_HOST)"
            } else {
                return "https://api.\(URL_HOST)"
            }
        }

        static var humanVerifyHost = "https://verify.\(Constants.App.appDomain)"
        static var accountHost = "https://account.\(Constants.App.appDomain)"
        static var appVersion: String {
            if let buildVersion = Int(Bundle.main.buildVersion) {
                return "ios-mail@\(Bundle.main.bundleShortVersion).\(buildVersion)"
            } else {
                return "ios-mail@\(Bundle.main.bundleShortVersion)-dev"
            }
        }
    }

    enum FreePlan {
        static let maxNumberOfFolders = 3
        static let maxNumberOfLabels = 3
    }

    enum ScheduleSend {
        static let minNumberOfMinutes = 5
        static var minNumberOfSeconds: TimeInterval { TimeInterval(self.minNumberOfMinutes * 60) }
        static let maxNumberOfSeconds: TimeInterval = 30 * 86400 // 86400 = 1 day
    }

    enum ImageProxy {
        static let cacheDiskSizeLimitInBytes: UInt = 1_024 * 1_024 * 1024   // 1 GiB
    }

    static let mailPlanIDs: Set<String> = ["ios_plus_12_usd_non_renewing",
                                           "iosmail_mail2022_12_usd_non_renewing",
                                           "iosmail_bundle2022_12_usd_non_renewing"]
    static let shownPlanNames: Set<String> = ["plus",
                                              "professional",
                                              "visionary",
                                              "mail2022",
                                              "bundle2022",
                                              "mailpro2022",
                                              "family2022",
                                              "visionary2022",
                                              "bundlepro2022"]
    static let defaultLocale = "en"

    #if !APP_EXTENSION
    static let defaultToolbarActions: [MessageViewActionSheetAction] = [
        .markUnread, .trash, .moveTo, .labelAs
    ]
    #endif
}
