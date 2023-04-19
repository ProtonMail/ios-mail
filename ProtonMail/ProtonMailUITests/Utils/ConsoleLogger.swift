// Copyright (c) 2023. Proton Technologies AG
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

import os.log

public protocol LogObject {
    static var osLog: OSLog { get }
}

public protocol Logger {
    func log(_ error: Error, osLogType: LogObject.Type)
    func log(_ event: String, osLogType: LogObject.Type)
}

public final class ConsoleLogger: Logger {
    public static let shared = ConsoleLogger()

    private init?() { }

    private func log(_ message: String, level: OSLogType, osLog: OSLog) {
        os_log("%{public}@", log: osLog, type: level, message)
    }

    public func log(_ error: Error, osLogType: LogObject.Type) {
        ConsoleLogger.shared?.log(String(describing: error), level: .error, osLog: osLogType.osLog)
    }

    public func log(_ event: String, osLogType: LogObject.Type) {
        ConsoleLogger.shared?.log(event, level: .default, osLog: osLogType.osLog)
    }
}
