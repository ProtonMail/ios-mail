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
    enum TaskType: CaseIterable {
        case backgroundProcessing
        case enterBackground

        var name: String {
            switch self {
            case .enterBackground:
                "Enter Background"
            case .backgroundProcessing:
                "Background Processing"
            }
        }

        var logFile: String {
            switch self {
            case .enterBackground:
                "enter_background.txt"
            case .backgroundProcessing:
                "background_processing.txt"
            }
        }
    }

    static func log(_ message: String, taskType: TaskType) {
        let timestamp = formatDate(Date())
        let log = "[\(timestamp)] [🔋 \(batteryState), \(batteryLevel)] \(message)\n"
        saveToLogFile(log, taskType: taskType)
    }

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

    private static func saveToLogFile(_ log: String, taskType: TaskType) {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(taskType.logFile)

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
    @State private var selectedTask: BackgroundEventsLogging.TaskType = .enterBackground
    @State private var logContent: String = "No logs".notLocalized

    var body: some View {
        VStack {
            // Toggle between log files
            Picker("Select Log File".notLocalized, selection: $selectedTask) {
                ForEach(BackgroundEventsLogging.TaskType.allCases, id: \.self) { task in
                    Text(task.name).tag(task)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Text("Background tasks logs".notLocalized)
                .font(.title)
                .padding()

            // Log content display
            ScrollView {
                Text(logContent)
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Buttons for Refresh and Clear Logs
            HStack {
                Button(action: loadLogFile) {
                    Label("Refresh".notLocalized, systemImage: "arrow.clockwise")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: clearLogFile) {
                    Label("Clear Logs".notLocalized, systemImage: "trash")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .onAppear(perform: loadLogFile)
        .onChange(of: selectedTask) { _ in
            loadLogFile()
        }
    }

    // Load log content based on the selected task
    func loadLogFile() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(selectedTask.logFile)

        if let content = try? String(contentsOf: fileURL, encoding: .utf8), !content.isEmpty {
            logContent = content
        } else {
            logContent = "Empty".notLocalized
        }
    }

    // Clear the selected log file
    func clearLogFile() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(selectedTask.logFile)

        do {
            try FileManager.default.removeItem(at: fileURL)
            logContent = "Empty".notLocalized // Update UI
            print("✅ Log file '\(selectedTask.logFile)' cleared")
        } catch {
            print("❌ Failed to clear log file '\(selectedTask.logFile)': \(error.localizedDescription)")
        }
    }
}

struct LogViewerView_Previews: PreviewProvider {
    static var previews: some View {
        LogViewerView()
    }
}
