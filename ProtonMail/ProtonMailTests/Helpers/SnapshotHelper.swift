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

import Foundation
import SnapshotTesting
import XCTest

func protonMailSnapshotDirectory(file: String) -> URL? {
    guard let srcroot = ProcessInfo.processInfo.environment["PROJECT_ROOT"] else {
        // Add [PROJECT_ROOT: ${SRCROOT}] to target env variables]
        return nil
    }
    let file = URL(fileURLWithPath: file)
    let rootURL = URL(fileURLWithPath: srcroot)
    let targetIndex = file.pathComponents.firstIndex(of: "ProtonMailTests")!
    let pathElements = file.pathComponents[targetIndex...]

    let fileName = file.deletingPathExtension().lastPathComponent

    let relativeFileURL = rootURL
        .deletingLastPathComponent()
        .appendingPathComponent("ProtonMail")
        .appending(path: pathElements.joined(separator: "/"))

    let snapshotDirectory = relativeFileURL
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileName)
    return snapshotDirectory
}

func protonMailAssertSnapshot<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    record recording: Bool = false,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    let failure = verifySnapshot(
        matching: try value(),
        as: snapshotting,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectory,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
    )
    guard let message = failure else { return }
    XCTFail(message, file: file, line: line)
}
