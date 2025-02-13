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

// MG: - This whole file content has to be removed after the testing

import Foundation
import UIKit

enum BackgroundEventsLogging {
    static func log(_ message: String) {
        let timestamp = formatDate(Date())
        let log = "[\(timestamp)] [🔋 \(batteryState), \(batteryLevel)] \(message)\n"
        saveToLogFile(log)
    }

    static let backgroundTasksLogFile = "background_log.txt"

    private static var batteryState: String {
        switch UIDevice.current.batteryState {
        case .charging:
            "Charnging"
        case .full:
            "Full"
        case .unknown:
            "Unknwon"
        case .unplugged:
            "Unplugged"
        @unknown default:
            "Unknown default"
        }
    }

    private static var batteryLevel: String {
        "\(UIDevice.current.batteryLevel * 100)%"
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func saveToLogFile(_ log: String) {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(backgroundTasksLogFile)

        if let data = log.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
    }
}

import SwiftUI

struct LogViewerView: View {
    @State private var logContent: String = "No logs".notLocalized

    var body: some View {
        VStack {
            Text("Background tasks logs".notLocalized)
                .font(.title)
                .padding()

            ScrollView {
                Text(logContent)
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            Button(action: loadLogFile) {
                Label("Refresh".notLocalized, systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear(perform: loadLogFile)
    }

    func loadLogFile() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(BackgroundEventsLogging.backgroundTasksLogFile)

        if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
            logContent = content
        } else {
            logContent = "Empty".notLocalized
        }
    }
}

struct LogViewerView_Previews: PreviewProvider {
    static var previews: some View {
        LogViewerView()
    }
}
