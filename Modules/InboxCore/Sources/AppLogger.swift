// Copyright (c) 2024 Proton Technologies AG
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

import OSLog
import proton_app_uniffi

public final class AppLogger: @unchecked Sendable {
    private static let shared = AppLogger()
    private let serialQueue = DispatchQueue(label: "\(Bundle.defaultIdentifier).AppLogger")

    private var loggers = [String: Any]()
    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? Bundle.defaultIdentifier
    }

    // MARK: Private methods

    static private func log(message: String, category: Category?, isError: Bool, isDebug: Bool) {
        logToUnifiedLoggingSystem(message: message, category: category, isError: isError)
        logToMailSDK(message: message, category: category, isError: isError, isDebug: isDebug)
    }

    /**
     It will log in the OS logging system. This logs are good for real time monitor in combination with relevant system logs 
     like app extension, push notifications, background tasks, ...
     */
    static private func logToUnifiedLoggingSystem(
        message: String,
        category: Category?,
        isError: Bool
    ) {
        let osLog = shared.osLog(for: category)
        if isError {
            osLog.error("\(message, privacy: .public)")
        } else {
            osLog.log("\(message, privacy: .public)")
        }
    }

    /**
     Adds the client logs to the SDK logfile
     */
    static private func logToMailSDK(
        message: String,
        category: Category?,
        isError: Bool,
        isDebug: Bool
    ) {
        var categorySection = "[App]"
        if let category {
            categorySection += " \(category.rawValue)"
        }
        categorySection += ": "
        let fileMessage = "\(categorySection)\(message)"

        if isError {
            rustLogError(line: fileMessage)
        } else if isDebug {
            rustLogDebug(line: fileMessage)
        } else {
            rustLogInfo(line: fileMessage)
        }
    }

    private func osLog(for category: Category?) -> Logger {
        let category = "[Proton] \(category?.rawValue ?? "")"
        var logger: Logger?
        serialQueue.sync {
            if !loggers.keys.contains(category) {
                loggers[category] = Logger(subsystem: bundleId, category: category)
            }
            logger = loggers[category] as? Logger
        }
        return logger ?? Logger()
    }

    // MARK: Public methods

    /// Logs a message into the unified logging system and the log file
    ///
    /// The unified logging system only works for iOS 15+
    ///
    /// - Parameters:
    ///   - message: log message in plain text.
    ///   - category: describes the scope for this message and helps filtering the system logs.
    ///   - isError: error logs show a visible indicator in the Console app.
    static public func log(
        message: String,
        category: Category? = nil,
        isError: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(message: message, category: category, isError: isError, isDebug: false)
    }

    /// Logs an error into the unified logging system
    ///
    /// - Parameters:
    ///   - error: the error to log.
    ///   - category: describes the scope for this message and helps filtering the system logs.
    static public func log(
        error: Error,
        category: Category? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(message: "\(error)", category: category, isError: true, isDebug: false)
    }

    /// Use this function instead of `log` to indicate that calls to this method can be removed from the codebase
    /// at some point in the near future. The reason to have this function is to have a clean log and avoid clutering it
    /// with useless entries. If you want to add meaningful permanent logs, use the `log` function instead.
    ///
    /// **If you are reading this documentation because you found a call to this function that is unnecessary, delete it :)**
    ///
    /// See `log(message:,category:,isError:)` for more details on the parameters.
    static public func logTemporarily(
        message: String,
        category: Category? = nil,
        isError: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(message: message, category: category, isError: isError, isDebug: true)
    }
}

extension AppLogger {

    public enum Category: String, CaseIterable {
        case appLifeCycle = "AppLifeCycle"
        case appRoute = "AppRoute"
        case thritySecondsBackgroundTask = "ThritySecondsBackgroundTask"
        case conversationDetail = "ConversationDetail"
        case composer = "Composer"
        case mailbox = "Mailbox"
        case mailboxActions = "MailboxActions"
        case notifications = "Notifications"
        case recurringBackgroundTask = "RecurringBackgroundTask"
        case rustLibrary = "RustLibrary"
        case search = "Search"
        case send = "Send"
        case userSessions = "UserSessions"
    }

    struct Caller {
        let file: String
        let function: String
        let line: Int
        let column: Int

        init(file: StaticString, function: StaticString, line: Int, column: Int) {
            self.file = "\(file)"
            self.function = "\(function)"
            self.line = line
            self.column = column
        }
    }
}
