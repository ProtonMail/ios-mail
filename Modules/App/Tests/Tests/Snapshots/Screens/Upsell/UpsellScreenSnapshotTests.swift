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
import proton_app_uniffi

@testable import InboxIAP

@MainActor
@Suite(.serialized)
struct UpsellScreenSnapshotTests {
    struct TestCase {
        let label: String
        let config: ViewImageConfig
        let upsellType: UpsellType
    }

    nonisolated private static let testCases: [TestCase] = {
        let orientations: [ViewImageConfig.Orientation] = [.portrait, .landscape]

        let devices: [(label: String, configFactory: (ViewImageConfig.Orientation) -> ViewImageConfig)] = [
            ("8", ViewImageConfig.iPhone8(_:)),
            ("13 Pro Max", ViewImageConfig.iPhone13ProMax(_:)),
        ]

        let upsellTypes: [UpsellType] = [.standard, .blackFriday(.wave1), .blackFriday(.wave2)]

        return orientations.flatMap { orientation in
            devices.flatMap { device in
                upsellTypes.map { upsellType in
                    .init(
                        label: "\(device.label)_\(orientation)_\(upsellType.label)",
                        config: device.configFactory(orientation),
                        upsellType: upsellType
                    )
                }
            }
        }
    }()

    @Test(arguments: testCases)
    func upsellScreen(testCase: TestCase) {
        let sut = UpsellScreen(model: .preview(entryPoint: .mailboxTopBar, upsellType: testCase.upsellType))
        let viewController = UIHostingController(rootView: sut)

        let strategy: Snapshotting<UIViewController, UIImage> = .image(
            on: testCase.config,
            drawHierarchyInKeyWindow: true,
            precision: 0.99
        )

        assertSnapshot(of: viewController, as: strategy, named: testCase.label)
    }
}

private extension UpsellType {
    var label: String {
        switch self {
        case .standard:
            "standard"
        case .blackFriday(.wave1):
            "BF_1"
        case .blackFriday(.wave2):
            "BF_2"
        }
    }
}
