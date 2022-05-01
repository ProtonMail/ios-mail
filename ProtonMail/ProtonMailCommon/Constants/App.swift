//
//  App.swift
//  ProtonMail - Created on 6/4/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

struct Constants {

    /// use this to replace the version compare to decide feature on/off. this is easier to track
    enum Feature {
        static let snoozeOn: Bool = false
    }

    enum App {
        static let AuthCacheVersion: Int = 15 // this is user info cache

        static let SpaceWarningThresholdDouble: Double = 90
        static let TourVersion : Int                   = 3

        static var AppVersion : Int              = 1
        
        // live api
        static var domain: String { BackendConfiguration.shared.environment.appDomain }
        static var URL_HOST: String { BackendConfiguration.shared.environment.apiDomain }
        static var API_PATH: String { BackendConfiguration.shared.environment.apiPath }
        static let DOH_ENABLE: Bool = true

        ///
        static let URL_Protocol = "https://"
        static let API_PREFIXED = "mail/v4"
        private static var API_HOST_URL: String {
            get {
                return URL_Protocol + URL_HOST
            }
        }

        static func apiHost() -> String {
            if let apiURLOverrideString = UserDefaults.standard.string(forKey: "ch.protonmail.protonmail.APIURLOverride"), let apiURLOverride = URL(string: apiURLOverrideString) {
                return apiURLOverride.absoluteString
            }
            return API_HOST_URL
        }

        static func captchaHost() -> String {
            if URL_HOST.starts(with: "api.") {
                return "https://\(URL_HOST)"
            } else {
                return "https://api.\(URL_HOST)"
            }
        }

        // app share group
        static var APP_GROUP: String {
            get {
                #if Enterprise
                return "group.com.protonmail.protonmail"
                #else
                return "group.ch.protonmail.protonmail"
                #endif
            }
        }

        static var humanVerifyHost = "https://verify.\(Constants.App.domain)"
        static var accountHost = "https://account.\(Constants.App.domain)"
    }

    enum FreePlan {
        static let maxNumberOfFolders = 3
        static let maxNumberOfLabels = 3
    }
    
    static let mailPlanIDs: Set<String> = ["ios_plus_12_usd_non_renewing",
                                           "iosmail_mail2021_12_usd_non_renewing",
                                           "iosmail_bundle2021_12_usd_non_renewing"]
    static let shownPlanNames: Set<String> = ["plus",
                                              "professional",
                                              "visionary",
                                              "mail2021",
                                              "bundle2021",
                                              "mailpro2021",
                                              "family2021",
                                              "visionary2021",
                                              "bundlepro2021"]
}
