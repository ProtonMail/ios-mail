// Copyright (c) 2022 Proton AG
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
import ProtonCoreLog

final class SystemLogger {
    private static let shared = SystemLogger()
    private let serialQueue = DispatchQueue(label: "ch.protonmail.protonmail.SystemLogger")

    private var loggers = [String: Any]()
    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "ch.proton"
    }

    // MARK: Private methods

    static private func log(message: String, category: Category?, isError: Bool, isDebug: Bool, caller: Caller) {
        // log the message in the unified logging system
        let osLog = shared.osLog(for: category)
        if isError {
            osLog.error("\(message, privacy: .public)")
        } else {
            osLog.log("\(message, privacy: .public)")
        }

        // log the message in the log file
        let fileMsg = "[\(category?.rawValue ?? "")] \(message)"
        if isDebug {
            PMLog.debug(fileMsg, file: caller.file, function: caller.function, line: caller.line, column: caller.column)
        } else if isError {
            PMLog.error(fileMsg, file: caller.file, function: caller.function, line: caller.line, column: caller.column)
        } else {
            PMLog.info(fileMsg, file: caller.file, function: caller.function, line: caller.line, column: caller.column)
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
    static func log(
        message: String,
        category: Category? = nil,
        isError: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        let caller = Caller(file: file, function: function, line: line, column: column)
        log(message: message, category: category, isError: isError, isDebug: false, caller: caller)
    }

    /// Logs an error into the unified logging system and the log file
    ///
    /// The unified logging system only works for iOS 15+
    ///
    /// - Parameters:
    ///   - error: the error to log.
    ///   - category: describes the scope for this message and helps filtering the system logs.
    static func log(
        error: Error,
        category: Category? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        let caller = Caller(file: file, function: function, line: line, column: column)
        log(message: "\(error)", category: category, isError: true, isDebug: false, caller: caller)
    }

    /// Use this function instead of `log` to indicate that calls to this method can be removed from the codebase
    /// at some point in the near future. The reason to have this function is to have a clean log and avoid clutering it
    /// with useless entries. If you want to add meaningful permanent logs, use the `log` function instead.
    ///
    /// **If you are reading this documentation because you found a call to this function that is unnecessary, delete it :)**
    ///
    /// See `log(message:,category:,isError:)` for more details on the parameters.
    static func logTemporarily(
        message: String,
        category: Category? = nil,
        isError: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        let caller = Caller(file: file, function: function, line: line, column: column)
        log(message: message, category: category, isError: isError, isDebug: true, caller: caller)
    }
}

extension SystemLogger {

    enum Category: String {
        case appLifeCycle = "AppLifeCycle"
        case appLock = "AppLock"
        case artificialSlowdown = "Artificial slowdown"
        case assertionFailure = "AssertionFailure"
        case connectionStatus = "ConnectionStatus"
        case contacts = "Contacts"
        case coreDataMigration = "CoreDataMigration"
        case draft = "Draft"
        case dynamicFontSize = "DynamicFontSize"
        case iap = "In-app purchases"
        case sendMessage = "SendMessage"
        case pushNotification = "PushNotification"
        case encryption = "Encryption"
        case coreData = "CoreData"
        case tests = "Tests"
        case queue = "Queue"
        case encryptedSearch = "EncryptedSearch"
        case blockSender = "BlockSender"
        case backgroundTask = "BackgroundTask"
        case loginUnlockFailed = "loginUnlockFailed"
        case eventLoop = "EventLoop"
        case restoreUserData = "RestoreUserData"
        case unauthorizedSession = "UnauthorizedSession"
        case notificationDebug = "NotificationDebug"
        case menuDebug = "MenuDebug"
        case emptyAlert = "EmptyAlert"
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
