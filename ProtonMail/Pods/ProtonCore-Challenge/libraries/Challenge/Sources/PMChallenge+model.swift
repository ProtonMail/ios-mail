//
//  PMChallenge+model.swift
//  ProtonCore-Challenge - Created on 6/19/20.
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
    public struct Cellular: Codable, Equatable {
        private(set) var mobileNetworkCode: String
        private(set) var mobileCountryCode: String
        init(networkCode: String?, countryCode: String?) {
            self.mobileNetworkCode = networkCode ?? ""
            self.mobileCountryCode = countryCode ?? ""
        }
    }
    
    public struct Frame: Codable, Equatable {
        private(set) var name: String
        public init(name: String?) throws {
            self.name = name ?? ""
        }
    }
    // Ask Anti-abuse team for the version
    static let VERSION = "2.0.3"
    public struct Challenge: Codable {
        
        public internal(set) var behaviouralFingerprint: BehaviouralFingerprint = BehaviouralFingerprint()
        public internal(set) var deviceFingerprint: DeviceFingerprint = DeviceFingerprint()
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(behaviouralFingerprint, forKey: .behaviouralFingerprint)
            try container.encode(deviceFingerprint, forKey: .deviceFingerprint)
        }
        
        public struct BehaviouralFingerprint: Codable {
            // MARK: Signup data
            
            /// version: String   new value for tracking the challenge object version. this value only change when challenge schema changed
            public internal(set) var v: String = VERSION

            /// Number of seconds from signup form load to start filling username input
            public internal(set) var timeUsername: [Int] = []
            /// Chars that typed in username input
            public internal(set) var keydownUsername: [String] = []
            /// Chars that deleted in username input
            public internal(set) var keydownRecovery: [String] = []
            /// Number of clicks/taps during username input
            public internal(set) var clickUsername: Int = 0
            /// Number of clicks/taps during recovery address input
            public internal(set) var clickRecovery: Int = 0
            // Number of seconds from signup form load to start filling recovery input
            public internal(set) var timeRecovery: [Int] = []
            /// Phrases copied during username inputs
            public internal(set) var copyUsername: [String] = []
            /// Phrases copied during recovery inputs
            public internal(set) var copyRecovery: [String] = []
            /// Phrases pasted during username inputs
            public internal(set) var pasteUsername: [String] = []
            /// Phrases pasted during recovery inputs
            public internal(set) var pasteRecovery: [String] = []
            
            public func encode(to encoder: Encoder) throws {
                // Since some of variables are deprecated
                // to remove these variables from JSONEncoder
                // implement this function
                // after removing these variables, consider to remove this function too
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(v, forKey: .v)
                try container.encode(timeUsername, forKey: .timeUsername)
                try container.encode(keydownUsername, forKey: .keydownUsername)
                try container.encode(keydownRecovery, forKey: .keydownRecovery)
                try container.encode(clickUsername, forKey: .clickUsername)
                try container.encode(clickRecovery, forKey: .clickRecovery)
                try container.encode(timeRecovery, forKey: .timeRecovery)
                try container.encode(copyUsername, forKey: .copyUsername)
                try container.encode(copyRecovery, forKey: .copyRecovery)
                try container.encode(pasteUsername, forKey: .pasteUsername)
                try container.encode(pasteRecovery, forKey: .pasteRecovery)
            }
            
            func asDictionary() throws -> [String: Any] {
                let data = try JSONEncoder().encode(self)
                guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let context = EncodingError.Context(codingPath: [],
                                                        debugDescription: "JSONEncoder cannot encode this value as [String: Any].")
                    throw EncodingError.invalidValue(data, context)
                }
                return dictionary
            }
        }
        
        public struct DeviceFingerprint: Codable {
            // MARK: Device relative setting
            /// Timezone of Operating System, e.g. `Asia/Taipei`
            public internal(set) var timezone: String = ""
            /// Timezone offset in minutes
            public internal(set) var timezoneOffset: Int = 0
            /// Is device jail break
            public internal(set) var isJailbreak = FileManager.isJailbreak()
            /// Device name with hash
            public internal(set) var deviceName: Int = -1
            /// App language
            public internal(set) var appLang = ""
            /// System setting region, not the real geo location
            public internal(set) var regionCode = ""
            /// Device capacity size in gigabyte
            public internal(set) var storageCapacity = FileManager.deviceCapacity() ?? -1
            /// Keyboards
            public internal(set) var keyboards: [String] = []
            /// Device cellulars information
            public internal(set) var cellulars: [Cellular] = []
            /// Returns a Boolean value indicating whether darken colors is enabled.
            public internal(set) var isDarkmodeOn: Bool = false
            /// Return user preferred content size
            public internal(set) var preferredContentSize: String = ""
            /// UUID for this app, will change after reinstall
            public internal(set) var uuid = UIDevice.current.identifierForVendor?.uuidString ?? "unknow"
            /// same as web, iframe-  name: username, recovery
            public internal(set) var frame: [Frame] = []
            
            public func encode(to encoder: Encoder) throws {
                // Since some of variables are deprecated
                // to remove these variables from JSONEncoder
                // implement this function
                // after removing these variables, consider to remove this function too
                var container = encoder.container(keyedBy: CodingKeys.self)
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
                try container.encode(frame, forKey: .frame)
            }
            
            func asDictionary() throws -> [String: Any] {
                let data = try JSONEncoder().encode(self)
                guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let context = EncodingError.Context(codingPath: [],
                                                        debugDescription: "JSONEncoder cannot encode this value as [String: Any].")
                    throw EncodingError.invalidValue(data, context)
                }
                return dictionary
            }
        }
        
        // MARK: - API
        
        /// Converts `PMChallenge` object into an array of json dictionaries.
        ///
        /// This function is the combination of `getUsernameChallenge()` and `getRecoveryChallenge()`.
        ///
        /// There are 3 possible situations:
        /// 1. Object is successfully converted into an array of json dictionaries and returned.
        /// 2. If the object failed to be converted into an array of json dictionaries,
        ///    it will try to convert it into a String value and return it if successful.
        /// 3. If the object can't be converted into a json dictionary nor json string, it will return an error message.
        public func allFingerprintDict() -> [[String: Any]] {
            convertIntoArryOfJson(asDict: asDictionary)
        }
        
        /// Converts `PMChallenge` object into an array of json dictionaries.
        ///
        /// This function is the combination of `getUsernameChallenge()` and `getRecoveryChallenge()`.
        ///
        /// There are 3 possible situations:
        /// 1. Object is successfully converted into an array of json dictionaries and returned.
        /// 2. If the object failed to be converted into an array of json dictionaries,
        ///    it will try to convert it into a String value and return it if successful.
        /// 3. If the object can't be converted into a json dictionary nor json string, it will return an error message.
        @available(*, deprecated, renamed: "allFingerprintDict")
        public func toDictArray() -> [[String: Any]] {
            allFingerprintDict()
        }
        
        /// Converts `PMChallenge` `DeviceFingerprint` object into an array of json dictionaries.
        ///
        /// This function is the combination of `getUsernameChallenge()` and `getRecoveryChallenge()`.
        /// However it only contains device fingerprint data.
        ///
        /// There are 3 possible situations:
        /// 1. Object is successfully converted into an array of json dictionaries and returned.
        /// 2. If the object failed to be converted into an array of json dictionaries,
        ///    it will try to convert it into a String value and return it if successful.
        /// 3. If the object can't be converted into a json dictionary nor json string, it will return an error message.
        public func deviceFingerprintDict() -> [[String: Any]] {
            convertIntoArryOfJson(asDict: deviceFingerprint.asDictionary)
        }
        
        /// Converts `PMChallenge` `BehaviouralFingerprint` object to json dictionary array
        ///
        /// This function is the combination of `getUsernameChallenge()` and `getRecoveryChallenge()`.
        /// However it only contains behavioural fingerprint data.
        ///
        /// There are 3 possible situations:
        /// 1. Object is successfully converted into an array of json dictionaries and returned.
        /// 2. If the object failed to be converted into an array of json dictionaries,
        ///    it will try to convert it into a String value and return it if successful.
        /// 3. If the object can't be converted into a json dictionary nor json string, it will return an error message.
        public func behaviouralFingerprintDict() -> [[String: Any]] {
            convertIntoArryOfJson(asDict: behaviouralFingerprint.asDictionary)
        }
        
        // MARK: - Internal
        
        /// Converts `PMChallenge` object into a json dictionary.
        /// - Throws: JSONSerialization exception.
        /// - Returns: Challenge data converted into a json dictionary.
        func asDictionary() throws -> [String: Any] {
            let data = try JSONEncoder().encode(self)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: [String: Any]] else {
                throw NSError()
            }
            return dictionary
                .reduce([String: Any]()) { emptyDict, tuple in
                    var dict = emptyDict
                    tuple.1.forEach { dict[$0.key] = $0.value }
                    return dict
                }
        }
        
        /// Converts `PMChallenge` object into a json encoded String.
        /// - Throws: JSONEncoder exception.
        /// - Returns: Challenge data converted into a json encoded String.
        func asString() throws -> String {
            let data = try JSONEncoder().encode(self)
            let str = String(data: data, encoding: .utf8)
            return str ?? ""
        }
        
        private func convertIntoArryOfJson(asDict: () throws -> [String: Any]) -> [[String: Any]] {
            do {
                let dict = try asDict()
                let username = getUsernameChallenge(dict: dict)
                let recovery = getRecoveryChallenge(dict: dict)
                return [username, recovery]
            } catch {
                let parsingError = error.localizedDescription
                do {
                    let challengeStr = try asString()
                    return [["StringValue": challengeStr]]
                } catch {
                    return [
                        ["Challenge-parse-dic-error": parsingError,
                         "Challenge-parse-string-error": error.localizedDescription]
                    ]
                }
            }
        }
        
        private func collectKeyboardData() -> [String] {
            let keyboards = UITextInputMode.activeInputModes
            
            let names = keyboards.map { info -> String in
                let id: String = (info.value(forKey: "identifier") as? String) ?? ""
                return id
            }
            return names
        }
        
        mutating func reset() {
            behaviouralFingerprint.timeUsername = []
            behaviouralFingerprint.keydownUsername = []
            behaviouralFingerprint.keydownRecovery = []
            behaviouralFingerprint.clickUsername = 0
            behaviouralFingerprint.clickRecovery = 0
            behaviouralFingerprint.timeRecovery = []
            behaviouralFingerprint.copyUsername = []
            behaviouralFingerprint.copyRecovery = []
            behaviouralFingerprint.pasteUsername = []
            behaviouralFingerprint.pasteRecovery = []
            deviceFingerprint.frame = []
        }
        
        mutating func fetchValues(device: UIDevice = .current,
                                  locale: Locale = .autoupdatingCurrent,
                                  timeZone: TimeZone = .autoupdatingCurrent) {
            deviceFingerprint.deviceName = device.name.rollingHash()
            deviceFingerprint.appLang = locale.languageCode ?? "unknow"
            deviceFingerprint.regionCode = locale.regionCode ?? "unknow"
            deviceFingerprint.timezone = timeZone.identifier
            deviceFingerprint.timezoneOffset = -1 * (timeZone.secondsFromGMT() / 60)
            deviceFingerprint.keyboards = collectKeyboardData()
            deviceFingerprint.cellulars = NetworkInformation.getCellularInfo()
            if #available(iOS 13.0, *) {
                deviceFingerprint.isDarkmodeOn = UITraitCollection.current.userInterfaceStyle == .dark
            }
            deviceFingerprint.preferredContentSize = UIApplication.getInstance()?.preferredContentSizeCategory.rawValue ?? UIContentSizeCategory.medium.rawValue
        }
        
        /// Convert `PMChallenge` object into a json dictionary
        ///
        /// This function is the combination of `asDictionary()` and `asString()`.
        /// This function is recommended to export all challenge data.
        ///
        /// There are 3 possible situations:
        /// 1. Object is successfully converted into an array of json dictionaries and returned.
        /// 2. If the object failed to be converted into an array of json dictionaries,
        ///    it will try to convert it into a String value and return it if successful.
        /// 3. If the object can't be converted into a json dictionary nor json string, it will return an error message.
        private func toDictionary() -> [String: Any] {
            do {
                return try asDictionary()
            } catch {
                let err1 = error.localizedDescription
                do {
                    let challengeStr = try asString()
                    return ["StringValue": challengeStr]
                } catch {
                    return ["Challenge-parse-dic-error": err1,
                            "Challenge-parse-string-error": error.localizedDescription]
                }
            }
        }
        
        private func getUsernameChallenge(dict: [String: Any]) -> [String: Any] {
            
            var challenge = dict

            // remove the recovery keys in username
            challenge["frame"] = ["name": "username"]
            challenge.removeValue(forKey: "keydownRecovery")
            challenge.removeValue(forKey: "pasteRecovery")
            challenge.removeValue(forKey: "clickRecovery")
            challenge.removeValue(forKey: "timeRecovery")
            challenge.removeValue(forKey: "copyRecovery")
            
            return challenge
        }
        
        private func getRecoveryChallenge(dict: [String: Any]) -> [String: Any] {
            
            var challenge = dict

            // remove the username keys in recovery
            challenge["frame"] = ["name": "recovery"]
            challenge.removeValue(forKey: "timeUsername")
            challenge.removeValue(forKey: "clickUsername")
            challenge.removeValue(forKey: "keydownUsername")
            challenge.removeValue(forKey: "copyUsername")
            challenge.removeValue(forKey: "pasteUsername")
            
            return challenge
        }
    }
}
