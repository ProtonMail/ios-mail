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

import SnapshotTesting
import SwiftUI
import XCTest

extension XCTestCase {

    func assertSnapshotsOnIPhoneX(
        of view: some View,
        named name: String? = nil,
        precision: Float = 1,
        record recording: Bool = false,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let styles: [UIUserInterfaceStyle] = [.light, .dark]
        styles.forEach { style in
            assertSnapshotOnIPhoneX(
                of: UIHostingController(rootView: view),
                style: style,
                named: name,
                precision: precision,
                record: recording,
                timeout: timeout,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    private func assertSnapshotOnIPhoneX(
        of controller: UIViewController,
        style: UIUserInterfaceStyle = .light,
        named name: String? = nil,
        precision: Float = 1,
        record recording: Bool = false,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        controller.overrideUserInterfaceStyle = style
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhoneX(.portrait), precision: precision),
            named: suffixedName(name: name, withStyle: style),
            record: recording,
            timeout: timeout,
            file: file,
            testName: testName,
            line: line
        )
    }

    // MARK: - Private

    private func suffixedName(name: String?, withStyle style: UIUserInterfaceStyle) -> String? {
        [name, style.humanReadable]
            .compactMap { $0 }
            .joined(separator: "_")
    }

}

private extension UIUserInterfaceStyle {

    var humanReadable: String {
        switch self {
        case .dark:
            return "dark"
        case .light:
            return "light"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }

}

