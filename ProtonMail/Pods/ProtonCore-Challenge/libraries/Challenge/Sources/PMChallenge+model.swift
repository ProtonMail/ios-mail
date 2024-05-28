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

#if os(iOS)

import UIKit
import Foundation
import ProtonCoreFoundations

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
    static let VERSION = "2.1.0"
    public struct Challenge {

        public internal(set) var behaviouralFingerprint: BehaviouralFingerprint = BehaviouralFingerprint()

        // MARK: - API
        public func signupFingerprintDict() -> [[String: Any]] {
            do {
                let deviceDictionary = DeviceFingerprint.deviceFingerprintDict(addVersion: false)
                let behaviouralDict = try behaviouralFingerprint.asDictionary()
                let username = getUsernameChallenge(dict: behaviouralDict).merging(deviceDictionary) { current, _ in
                    current
                }
                let recovery = getRecoveryChallenge(dict: behaviouralDict).merging(deviceDictionary) { current, _ in
                    current
                }
                return [username, recovery]
            } catch {
                // Abuse team doesn't use this value
                // This more like a debug information for client
                return [
                    ["Challenge-parse-dic-error": error.localizedDescription]
                ]
            }
        }

        // MARK: - Internal

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

extension PMChallenge.Challenge {
    public struct DeviceFingerprint: Codable {
        // MARK: Device relative setting
        /// Timezone of Operating System, e.g. `Asia/Taipei`
        public internal(set) var timezone: String = ""
        /// Timezone offset in minutes
        public internal(set) var timezoneOffset: Int = 0
        /// Is device jailbroken, the spelling is meant to match BE format
        public internal(set) var isJailbreak = FileManager.isJailbroken()
        /// Device name with hash
        public internal(set) var deviceName: Int = -1
        /// App language
        public internal(set) var appLang = ""
        /// System setting region, not the real geo location
        public internal(set) var regionCode = ""
        /// Keyboards
        public internal(set) var keyboards: [String] = []
        /// Device cellulars information
        public internal(set) var cellulars: [PMChallenge.Cellular] = []
        /// Returns a Boolean value indicating whether darken colors is enabled.
        public internal(set) var isDarkmodeOn: Bool = false
        /// Return user preferred content size
        public internal(set) var preferredContentSize: String = ""
        /// UUID for this app, will change after reinstall
        public internal(set) var uuid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

        private init(
            device: UIDevice = .current,
            locale: Locale = .autoupdatingCurrent,
            timeZone: TimeZone = .autoupdatingCurrent,
            userDefaults: UserDefaults = .standard
        ) {

            self.appLang = locale.languageCode ?? "unknown"
            self.cellulars = NetworkInformation.getCellularInfo()
            self.deviceName = device.name.rollingHash()
            self.isDarkmodeOn = UITraitCollection.current.userInterfaceStyle == .dark
            self.isJailbreak = FileManager.isJailbroken()

            self.regionCode = locale.regionCode ?? "unknown"
            self.timezone = timeZone.identifier
            self.timezoneOffset = -1 * (timeZone.secondsFromGMT() / 60)
            self.uuid = device.identifierForVendor?.uuidString ?? "unknown"

            if let keyboardNames = userDefaults.object(forKey: "AppleKeyboards") as? [String] {
                self.keyboards = Array(Set(keyboardNames))
            } else {
                self.keyboards = []
            }
        }

        // Make sure `DeviceFingerprint` is initialized in main thread
        static func generate(
            device: UIDevice = .current,
            locale: Locale = .autoupdatingCurrent,
            timeZone: TimeZone = .autoupdatingCurrent,
            userDefaults: UserDefaults = .standard
        ) -> DeviceFingerprint {
            var fingerprint: DeviceFingerprint = DeviceFingerprint(
                device: device,
                locale: locale,
                timeZone: timeZone,
                userDefaults: userDefaults
            )
            let semaphore = DispatchSemaphore(value: 0)
            runInMainThread {
                // Needs to run in main thread
                fingerprint.preferredContentSize = UIApplication.getInstance()?.preferredContentSizeCategory.rawValue ?? UIContentSizeCategory.medium.rawValue
                semaphore.signal()
            }
            semaphore.wait()
            return fingerprint
        }

        private static func runInMainThread(closure: @escaping () -> Void) {
            if Thread.isMainThread {
                closure()
            } else {
                DispatchQueue.main.async {
                    closure()
                }
            }
        }

        func asDictionary(addVersion: Bool = false) throws -> [String: Any] {
            let data = try JSONEncoder().encode(self)
            guard var dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                let context = EncodingError.Context(codingPath: [],
                                                    debugDescription: "JSONEncoder cannot encode this value as [String: Any].")
                throw EncodingError.invalidValue(data, context)
            }
            if addVersion {
                dictionary["v"] = PMChallenge.VERSION
            }
            return dictionary
        }

        static func deviceFingerprintDict(addVersion: Bool) -> [String: Any] {
            let fingerprint = DeviceFingerprint.generate()
            do {
                let dictionary = try fingerprint.asDictionary(addVersion: addVersion)
                return dictionary
            } catch {
                // Abuse team doesn't use this value
                // This more like a debug information for client
                return ["Challenge-parse-dic-error": error.localizedDescription]
            }
        }

        static func deviceFingerprintDictInArray() -> [[String: Any]] {
            return [deviceFingerprintDict(addVersion: true)]
        }
    }

    public struct BehaviouralFingerprint: Codable {
        // MARK: Signup data

        /// version: String   new value for tracking the challenge object version. this value only change when challenge schema changed
        public internal(set) var v: String = PMChallenge.VERSION

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
}

#endif

// swiftlint:enable identifier_name
