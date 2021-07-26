//
//  PMChallenge+model.swift
//  ProtonCore-Challenge - Created on 6/19/20.
//
//  Copyright (c) 2019 Proton Technologies AG
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

// swiftlint:disable identifier_name

import UIKit
import Foundation
import ProtonCore_Foundations

// MARK: Enum
extension PMChallenge {

    public typealias TextFieldType = ChallengeTextFieldType

    public enum TextFieldInterceptError: Error, LocalizedError {
        case delegateMissing

        var localizedDescription: String {
            switch self {
            case .delegateMissing:
                return "Delegate of textfield is missing"
            }
        }
    }

    public enum TimerError: Error, LocalizedError {
        case verificationTimerError

        var localizedDescription: String {
            switch self {
            case .verificationTimerError:
                return "Please call function requestVerify() when user try to request verification"
            }
        }
    }
}

// MARK: struct/ class
extension PMChallenge {
    public struct Cellular: Codable {
        private(set) var mobileNetworkCode: String
        private(set) var mobileCountryCode: String
        init(networkCode: String?, countryCode: String?) {
            self.mobileNetworkCode = networkCode ?? ""
            self.mobileCountryCode = countryCode ?? ""
        }
    }

    public struct Challenge: Codable {
        // MARK: Signup data
        @available(*, deprecated, message: "This parameter will be removed in the future")
        public internal(set) var usernameChecks: [String] = []
        /// Number of seconds it took to verify sms/email/catpcha/payment
        @available(*, deprecated, message: "This parameter will be removed in the future")
        public internal(set) var time_human: Int = 0
        /// Number of seconds that user focus on password textField.
        @available(*, deprecated, message: "This parameter will be removed in the future")
        public internal(set) var time_pass: Int = 0

        /// Number of seconds from signup form load to start filling username input
        public internal(set) var time_user: [Int] = []
        /// Chars that typed in username input
        public internal(set) var usernameTypedChars: [String] = []
        /// Chars that deleted in username input
        public internal(set) var recoverTypedChars: [String] = []
        /// Number of clicks/taps during username input
        public internal(set) var click_user: Int = 0
        /// Number of clicks/taps during recovery address input
        public internal(set) var click_recovery: Int = 0
        /// Phrases copied during username inputs
        public internal(set) var copy_username: [String] = []
        /// Phrases copied during recovery inputs
        public internal(set) var copy_recovery: [String] = []
        /// Phrases pasted during username inputs
        public internal(set) var paste_username: [String] = []
        /// Phrases pasted during recovery inputs
        public internal(set) var paste_recovery: [String] = []

        // MARK: Device relative setting
        /// Timezone of Operating System, e.g. `Asia/Taipei`
        public private(set) var timezone: String = ""
        /// Timezone offset in minutes
        public private(set) var timezoneOffset: Int = 0
        /// Is device jail break
        public private(set) var isJailbreak = FileManager.isJailbreak()
        /// Device name with hash
        public private(set) var deviceName: Int = -1
        /// App language
        public private(set) var appLang = ""
        /// System setting region, not the real geo location
        public private(set) var regionCode = ""
        /// Device capacity size in gigabyte
        public private(set) var storageCapacity = FileManager.deviceCapacity() ?? -1
        /// Keyboards
        public private(set) var keyboards: [String] = []
        /// Device cellulars information
        public private(set) var cellulars: [Cellular] = []
        /// Returns a Boolean value indicating whether darken colors is enabled.
        public private(set) var isDarkmodeOn: Bool = false
        /// Return user preferred content size
        public private(set) var preferredContentSize: String = ""
        /// UUID for this app, will change after reinstall
        public private(set) var uuid = UIDevice.current.identifierForVendor?.uuidString ?? "unknow"

        public func encode(to encoder: Encoder) throws {
            // Since some of variables are deprecated
            // to remove these variables from JSONEncoder
            // implement this function
            // after removing these variables, consider to remove this function too
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(time_user, forKey: .time_user)
            try container.encode(usernameTypedChars, forKey: .usernameTypedChars)
            try container.encode(recoverTypedChars, forKey: .recoverTypedChars)
            try container.encode(click_user, forKey: .click_user)
            try container.encode(click_recovery, forKey: .click_recovery)
            try container.encode(copy_username, forKey: .copy_username)
            try container.encode(copy_recovery, forKey: .copy_recovery)
            try container.encode(paste_username, forKey: .paste_username)
            try container.encode(paste_recovery, forKey: .paste_recovery)
            try container.encode(timezone, forKey: .timezone)
            try container.encode(timezoneOffset, forKey: .timezoneOffset)
            try container.encode(isJailbreak, forKey: .isJailbreak)
            try container.encode(deviceName, forKey: .deviceName)
            try container.encode(appLang, forKey: .appLang)
            try container.encode(regionCode, forKey: .regionCode)
            try container.encode(storageCapacity, forKey: .storageCapacity)
            try container.encode(keyboards, forKey: .keyboards)
            try container.encode(cellulars, forKey: .cellulars)
            try container.encode(isDarkmodeOn, forKey: .isDarkmodeOn)
            try container.encode(preferredContentSize, forKey: .preferredContentSize)
            try container.encode(uuid, forKey: .uuid)
        }

        mutating func reset() {
            self.time_user = []
            self.usernameTypedChars = []
            self.recoverTypedChars = []
            self.click_user = 0
            self.click_recovery = 0
            self.copy_username = []
            self.copy_recovery = []
            self.paste_username = []
            self.paste_recovery = []
        }
        
        mutating func fetchValues() {
            self.deviceName = UIDevice.current.name.rollingHash()
            self.appLang = Locale.current.languageCode ?? "unknow"
            self.regionCode = Locale.current.regionCode ?? "unknow"
            let currentTimezone = TimeZone.current
            self.timezone = currentTimezone.identifier
            self.timezoneOffset = -1 * (currentTimezone.secondsFromGMT() / 60)
            self.keyboards = self.collectKeyboardData()
            self.cellulars = NetworkInformation.getCellularInfo()
            if #available(iOS 13.0, *) {
                self.isDarkmodeOn = UITraitCollection.current.userInterfaceStyle == .dark
            }
            self.preferredContentSize = UIApplication.getInstance()?.preferredContentSizeCategory.rawValue ?? UIContentSizeCategory.medium.rawValue
        }
        
        /// Transfer `PMChallenge` object to json dictionary
        ///
        /// This function is the combination of `asDictionary()` and `asString()`. Recommend use this function to export challenge data
        ///
        /// There are 3 possible situations
        /// 1. Object transfer to json dictionary successful, return this json dictionary
        /// 2. If object transfer to json dictionary failed, will try to transfer to string value, return this string value if successful
        /// 3. If object can't be transferred to json dictionary nor json string, will return error message
        
        public func toDictionary() -> [String: Any] {
            do {
                var challenge = try self.asDictionary()
                challenge.removeValue(forKey: "usernameChecks")
                challenge.removeValue(forKey: "time_human")
                challenge.removeValue(forKey: "time_pass")
                return challenge
            } catch {
                let err1 = error.localizedDescription
                do {
                    let challengeStr = try self.asString()
                    return ["StringValue": challengeStr]
                } catch {
                    return ["Challenge-parse-dic-error": err1,
                            "Challenge-parse-string-error": error.localizedDescription]
                }
            }
        }
        
        /// Transfer `PMChallenge` object to json dictionary
        /// - Throws: JSONSerialization exception
        /// - Returns: Challenge data in json dictionary type
        public func asDictionary() throws -> [String: Any] {
            let data = try JSONEncoder().encode(self)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw NSError()
            }
            return dictionary
        }

        /// Transfer `PMChallenge` object to json string
        /// - Throws: JSONEncoder exception
        /// - Returns: Challenge data in json string type
        public func asString() throws -> String {
            let data = try JSONEncoder().encode(self)
            let str = String(data: data, encoding: .utf8)
            return str ?? ""
        }
        
        private func collectKeyboardData() -> [String] {
            let keyboards = UITextInputMode.activeInputModes
            
            let names = keyboards.map { info -> String in
                let id: String = (info.value(forKey: "identifier") as? String) ?? ""
                if id.contains("emoji") {
                    let emoji = UserDefaults.recentlyEmoji().joined().rollingHash()
                    return "\(id)-\(emoji)"
                } else {
                    return id
                }
            }
            return names
        }
    }
}
