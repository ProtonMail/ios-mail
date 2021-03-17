//
//  PMLog.swift
//  PMLog
//
//  Created by Igor Kulman on 12/11/2020.
//

import Foundation

public class PMLog {

    public enum LogLevel {
        case fatal, error, warn, info, debug, trace

        fileprivate var description: String {
            switch self {
            case .fatal:
                return "FATAL"
            case .error:
                return "ERROR"
            case .warn:
                return "WARN"
            case .info:
                return "INFO"
            case .debug:
                return "DEBUG"
            case .trace:
                return "TRACE"
            }
        }
    }

    public static var callback: ((String, LogLevel) -> Void)?

    // MARK: - Properties

    public static let logsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first

    private static let maxLogLines = 2000

    public static var logFile: URL? {
        let file = logsDirectory?.appendingPathComponent("logs.txt", isDirectory: false)

        #if !os(OSX)
        try? (file as NSURL?)?.setResourceValue( URLFileProtection.complete, forKey: .fileProtectionKey)
        #endif

        return file
    }

    public static func logsContent() -> String {
        do {
            guard let logFile = logFile else {
                return ""
            }
            return try String(contentsOf: logFile, encoding: .utf8)
        } catch {
            return ""
        }
    }

    // MARK: - Actions

    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(message, level: .debug, file: file, function: function, line: line, column: column)
    }

    public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(message, level: .info, file: file, function: function, line: line, column: column)
    }

    public static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(message, level: .error, file: file, function: function, line: line, column: column)
    }

    public static func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        self.error(error.localizedDescription, file: file, function: function, line: line, column: column)
    }

    public static func printToConsole(_ text: String) {
        #if DEBUG
        print(text)
        #endif
    }

    // MARK: - Internal

    private static func log(_ message: String, level: LogLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        let log = "\(Date()) : \(level.description) : \((file as NSString).lastPathComponent) : \(function) : \(line) : \(column) - \(message)"
        printToConsole(log)

        callback?(message, level)

        guard let logPath = logFile else {
            return
        }

        pruneLogs()

        do {
            let fileHandle = try FileHandle(forWritingTo: logPath)
            fileHandle.seekToEndOfFile()
            fileHandle.write("\(log)\n".data(using: .utf8)!)
            fileHandle.closeFile()
        } catch {
            do {
                try "\(log)\n".data(using: .utf8)?.write(to: logPath)
            } catch {
                printToConsole(error.localizedDescription)
            }
        }
    }

    private static func pruneLogs() {
        do {
            guard let logUrl = logFile else {
                return
            }

            let logContents = try String(contentsOf: logUrl, encoding: .utf8)
            let lines = logContents.components(separatedBy: .newlines)
            if lines.count > maxLogLines {
                let prunedLines = Array(lines.dropFirst(lines.count - maxLogLines))
                let replacementText = prunedLines.joined(separator: "\n")
                try replacementText.data(using: .utf8)?.write(to: logUrl)
            }
        } catch let error { printToConsole(error.localizedDescription) }
    }
}
