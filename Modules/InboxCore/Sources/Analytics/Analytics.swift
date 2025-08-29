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

import Sentry

public final actor Analytics {
    enum State: Equatable {
        case enabled(configuration: UserAnalyticsConfiguration)
        case disabled

        var isEnabled: Bool {
            switch self {
            case .enabled:
                true
            case .disabled:
                false
            }
        }

        func shouldConfigure(with newConfiguration: UserAnalyticsConfiguration) -> Bool {
            switch self {
            case .enabled(let configuration):
                newConfiguration != configuration
            case .disabled:
                true
            }
        }
    }

    private let sentryAnalytics: SentryAnalytics
    private var state: State = .disabled

    public init(sentryAnalytics: SentryAnalytics = .production) {
        self.sentryAnalytics = sentryAnalytics
    }

    public func disable() {
        guard state.isEnabled else { return }
        sentryAnalytics.stop()
        state = .disabled
    }

    public func enable(configuration: UserAnalyticsConfiguration) {
        guard state.shouldConfigure(with: configuration) else { return }
        sentryAnalytics.stop()
        sentryAnalytics.start { options in
            options.dsn = SentryConfiguration.dsn

            options.enableAutoPerformanceTracing = false
            options.enableAppHangTracking = false
            options.enableCaptureFailedRequests = false

            options.enableNetworkTracking = configuration.crashReports
            options.enableNetworkBreadcrumbs = configuration.crashReports
            options.enableAutoSessionTracking = configuration.crashReports
            options.enableAutoBreadcrumbTracking = configuration.crashReports
            options.enableWatchdogTerminationTracking = configuration.crashReports

            options.enableCrashHandler = configuration.crashReports

            options.beforeSend = { [weak self] event in
                guard let self = self, event.isCrash else {
                    return event
                }

                // Note: At the time of this MR, Sentry does not support attachments for crash reports
                // It does however support attachments for other kinds of events.
                let cachePath = FileManager.default.sharedCacheDirectory.path()
                guard let last90KB = self.readLastBytes(from: "\(cachePath)/proton-mail-uniffi.log", byteCount: 90 * 1024) else { return event }

                // Divide the data into ~3kb chunks and write them to extra fields.
                // Extra fields have a 4kb limit. The whole payload has a max uncompressed size of 1MB.
                // To be on the safe side, only 90kb of the rust log are included. A crash has a lot of other data in other fields.
                // This is better than using breadcrumbs. The size of all Breadcrumbs together cannot exceed 8196 characters.
                // About 10 times less of what we can send with this solution.
                guard let logs = String(data: last90KB, encoding: .utf8) else { return event }

                event.extra = event.extra ?? [:]

                let chunkedLogs = logs.split(separator: "\n").chunked(into: 30)

                // keys need to look like this:
                // rust_log_001
                // rust_log_002
                // ...
                // rust_log_021
                // So that they show up in order in the Sentry dashboard.
                for (index, chunk) in chunkedLogs.enumerated() {
                    let zeroPrefix = Array.init(repeating: "0", count: chunkedLogs.count.digitCount - index.digitCount).joined()
                    event.extra?["rust_log_\(zeroPrefix)\(index)"] = chunk.joined(separator: "\n")
                }

                return event
            }
        }

        state = .enabled(configuration: configuration)
    }

    private enum SentryConfiguration {
        static let dsn = "https://a3be1429a241459790c784466f194565@api.protonmail.ch/core/v4/reports/sentry/83"
    }

    nonisolated private func readLastBytes(from filePath: String, byteCount: UInt64) -> Data? {
        guard let fileHandle = FileHandle(forReadingAtPath: filePath) else {
            print("Could not open file")
            return nil
        }

        defer { fileHandle.closeFile() }

        do {
            let fileSize = try fileHandle.seekToEnd()
            fileHandle.seek(toFileOffset: fileSize < byteCount ? 0 : fileSize - byteCount)

            let data = fileHandle.readDataToEndOfFile()
            return data
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
}

extension Event {
    var isCrash: Bool {
        if level == .fatal {
            return true
        }

        guard let exceptions = self.exceptions else { return false }

        // Check for unhandled exceptions or for specific crash mechanisms
        return exceptions.contains(where: {
            $0.mechanism?.handled == false || ["signal", "mach_exception", "uncaught_exception"].contains($0.mechanism?.type)
        })
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        var chunks: [[Element]] = []
        var currentIndex = 0

        while currentIndex < count {
            let endIndex = Swift.min(currentIndex + size, count)
            chunks.append(Array(self[currentIndex..<endIndex]))
            currentIndex = endIndex
        }

        return chunks
    }
}

extension Int {
    var digitCount: Int {
        return String(abs(self)).count
    }
}
