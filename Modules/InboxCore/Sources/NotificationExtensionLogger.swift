// Copyright (c) 2025 Proton Technologies AG
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

public final class NotificationExtensionLogger: @unchecked Sendable {
    public static let shared = NotificationExtensionLogger()
    private let serialQueue = DispatchQueue(label: "me.proton.mail.NotificationExtensionLogger")
    private let logFileURL: URL

    private init() {
        logFileURL = FileManager.default.sharedCacheDirectory.appending(path: "extension.log")
        appendLine("---- Notification Extension ---- Started at \(Self.fullTimestamp())")
    }

    public static func log(message: String, category: AppLogger.Category?, isError: Bool = false) {
        shared.write(message: message, category: category, isError: isError)
    }

    private func write(message: String, category: AppLogger.Category?, isError: Bool) {
        let level = isError ? "ERROR" : " INFO"
        var cat = "[NotificationExtension]"
        if let category { cat += " \(category.rawValue)" }
        let line = "\(Self.timestamp()) \(level) \(cat): \(message)"
        appendLine(line)
    }

    private func appendLine(_ line: String) {
        serialQueue.async {
            guard let data = (line + "\n").data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                guard let handle = try? FileHandle(forWritingTo: self.logFileURL) else { return }
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                try? data.write(to: self.logFileURL, options: .atomic)
            }
        }
    }

    /// `yyyy-MM-dd HH:mm:ss.SSS ±HH:mm`
    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZZZZ"
        return formatter.string(from: Date())
    }

    /// `yyyy-MM-dd HH:mm:ss.SSSSSS ±HH:mm` — matches the precision of the Rust SDK header line
    private static func fullTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS ZZZZZ"
        return formatter.string(from: Date())
    }
}
