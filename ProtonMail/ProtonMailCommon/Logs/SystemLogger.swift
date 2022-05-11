// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import OSLog

class SystemLogger {
    private static let shared = SystemLogger()

    private var loggers = [String: Any]()
    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "ch.proton"
    }

    // MARK: Private methods

    @available(iOS 15, *)
    private func osLog(for category: Category?) -> Logger {
        let category = "[Proton] \(category?.rawValue ?? "")"
        if !loggers.keys.contains(category) {
            loggers[category] = Logger(subsystem: bundleId, category: category)
        }
        return loggers[category] as? Logger ?? Logger()
    }

    // MARK: Public methods

    /// Log a message into the unified logging system for a specific category. It only works for iOS 15 and above.
    /// - Parameters:
    ///   - message: log message in plain text.
    ///   - redactedInfo: part of the log message that will show redacted with the `<private>` string.
    ///   - category: describes the scope for this message and helps filtering the system logs.
    ///   - isError: error logs show a visible indicator in the Console app.
    static func log(message: String, redactedInfo: String? = nil, category: Category? = nil, isError: Bool = false) {
        if #available(iOS 15, *) {
            let osLog = shared.osLog(for: category)
            let redacted = redactedInfo ?? ""
            if isError {
                if !redacted.isEmpty {
                    osLog.error("\(message, privacy: .public) \(redacted, privacy: .private)")
                } else {
                    osLog.error("\(message, privacy: .public)")
                }
            } else {
                if !redacted.isEmpty {
                    osLog.log("\(message, privacy: .public) \(redacted, privacy: .private)")
                } else {
                    osLog.log("\(message, privacy: .public)")
                }
            }
        }
    }

    /// Use this function instead of `log` to indicate that calls to this method can be removed from the codebase
    /// at some point in the near future. The reason to have this function is to have a clean log and avoid clutering it
    /// with useless entries. If you want to add meaningful permanent logs, use the `log` function instead.
    ///
    /// **If you are reading this documentation because you found a call to this function that is unnecessary, delete it :)**
    ///
    /// See `log(message:,isDataSensitive:,category:,isError:)` for more details on the parameters.
    static func logTemporarily(message: String, redactedInfo: String? = nil, category: Category? = nil, isError: Bool = false) {
        log(message: message, redactedInfo: redactedInfo, category: category, isError: isError)
    }
}

extension SystemLogger {

    enum Category: String {
        case appLifeCycle = "AppLifeCycle"
        case pushNotification = "PushNotification"
        case encryption = "Encryption"
        case coreData = "CoreData"
        case tests = "Tests"
    }
}
