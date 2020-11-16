//
//  PMFingerPrint+model.swift
//  ProtonMail - Created on 6/19/20.
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

import UIKit
import Foundation

// MARK: Enum
extension PMFingerprint {
    public enum TextFieldType {
        /// TextField for username
        case username
        /// TextField for password
        case password
        /// TextField for password confirm
        case confirm
        /// TextField for recovery mail
        case recovery
        /// TextField for verification
        case verification
    }
    
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
extension PMFingerprint {
    public struct Cellular: Codable {
        private(set) var mobileNetworkCode: String
        private(set) var mobileCountryCode: String
        private(set) var carrierName: String
        init(networkCode: String?, countryCode: String?, carrierName: String?) {
            self.mobileNetworkCode = networkCode ?? ""
            self.mobileCountryCode = countryCode ?? ""
            self.carrierName = carrierName ?? ""
        }
    }
    
    public struct Fingerprint: Codable {
        // MARK: Signup data
        public internal(set) var usernameChecks: [String] = []
        /// Number of seconds it took to verify sms/email/catpcha/payment
        public internal(set) var time_human: Int = 0
        /// Number of seconds that user focus on password textField.
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
        
        mutating func reset() {
            self.usernameChecks = []
            self.time_human = 0
            self.time_user = []
            self.time_pass = 0
            self.usernameTypedChars = []
            self.recoverTypedChars = []
            self.click_user = 0
            self.click_recovery = 0
            self.copy_username = []
            self.copy_recovery = []
            self.paste_username = []
            self.paste_recovery = []
        }
        
        public func asDictionary() throws -> [String: Any] {
            let data = try JSONEncoder().encode(self)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw NSError()
            }
            return dictionary
        }
        
        public func asString() throws -> String {
            let data = try JSONEncoder().encode(self)
            let str = String(data: data, encoding: .utf8)
            return str ?? ""
        }
 
        mutating func fetchValues() {
            self.deviceName = UIDevice.current.name.rollingHash()
            self.appLang = Locale.current.languageCode ?? "unknow"
            self.regionCode = Locale.current.regionCode ?? "unknow"
            let currentTimezone = TimeZone.current
            self.timezone = currentTimezone.identifier
            self.timezoneOffset = -1 * (currentTimezone.secondsFromGMT()/60)
            if var keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] {
                let emoji = UserDefaults.recentlyEmoji().joined().rollingHash()
                keyboards = keyboards.map {$0.contains("emoji") ? "\($0)-\(emoji)": $0}
                self.keyboards = keyboards
            }
            self.cellulars = NetworkInformation.getCellularInfo()
            if #available(iOS 13.0, *) {
                self.isDarkmodeOn = UITraitCollection.current.userInterfaceStyle == .dark
            }
            self.preferredContentSize = UIApplication.shared.preferredContentSizeCategory.rawValue
        }
    }
}
