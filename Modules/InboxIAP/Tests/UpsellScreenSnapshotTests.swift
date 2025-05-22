//
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

import InboxSnapshotTesting
import SnapshotTesting
import SwiftUI
import Testing

@testable import InboxIAP

@MainActor
struct UpsellScreenSnapshotTests {
    struct TestCase {
        let label: String
        let config: ViewImageConfig
    }

    nonisolated private static let testCases: [TestCase] = {
        let orientations: [ViewImageConfig.Orientation] = [.portrait, .landscape]

        let devices: [(label: String, configFactory: (ViewImageConfig.Orientation) -> ViewImageConfig)] = [
            ("8", ViewImageConfig.iPhone8(_:)),
            ("13 Pro Max", ViewImageConfig.iPhone13ProMax(_:)),
        ]

        return orientations.flatMap { orientation in
            devices.map { device in
                let config = device.configFactory(orientation)
                return .init(label: "\(device.label)_\(orientation)", config: config)
            }
        }
    }()

    @Test(arguments: testCases)
    func upsellScreen(testCase: TestCase) {
        let sut = UpsellScreen(model: .preview)
        let viewController = UIHostingController(rootView: sut)

        assertSnapshots(matching: viewController, on: [(testCase.label, testCase.config)], styles: [.dark])
    }
}
