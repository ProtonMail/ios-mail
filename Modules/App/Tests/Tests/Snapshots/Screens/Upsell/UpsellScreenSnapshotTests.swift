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
struct UpsellScreenSnapshotTests {
    enum SelectedCycle: String {
        case yearly
        case monthly

        var lengthInMonths: Int {
            switch self {
            case .yearly: 12
            case .monthly: 1
            }
        }
    }

    struct TestCase {
        let label: String
        let config: ViewImageConfig
        let upsellType: UpsellType
        let selectedCycle: SelectedCycle
    }

    nonisolated private static let testCases: [TestCase] = {
        let orientations: [ViewImageConfig.Orientation] = [.portrait, .landscape]

        let devices: [(label: String, configFactory: (ViewImageConfig.Orientation) -> ViewImageConfig)] = [
            ("8", ViewImageConfig.iPhone8(_:)),
            ("13 Pro Max", ViewImageConfig.iPhone13ProMax(_:)),
        ]

        let upsellTypes: [UpsellType] = [.mailPlus, .unlimited]
        let selectedCycles: [SelectedCycle] = [.yearly, .monthly]

        return orientations.flatMap { orientation in
            devices.flatMap { device in
                upsellTypes.flatMap { upsellType in
                    selectedCycles.map { selectedCycle in
                        .init(
                            label: "\(device.label)_\(orientation)_\(upsellType.label)_\(selectedCycle.rawValue)",
                            config: device.configFactory(orientation),
                            upsellType: upsellType,
                            selectedCycle: selectedCycle
                        )
                    }
                }
            }
        }
    }()

    @Test(arguments: testCases)
    func upsellScreen(testCase: TestCase) {
        let model = UpsellScreenModel.preview(entryPoint: .mailboxTopBar, upsellType: testCase.upsellType)
        if let instance = model.planInstances.first(where: { $0.cycleInMonths == testCase.selectedCycle.lengthInMonths }) {
            model.selectedInstanceId = instance.storeKitProductId
        }

        let sut = UpsellScreen(model: model)
        let viewController = UIHostingController(rootView: sut)
        viewController.view.backgroundColor = .black
        viewController.overrideUserInterfaceStyle = .dark

        let strategy: Snapshotting<UIViewController, UIImage> = .image(
            on: testCase.config,
            drawHierarchyInKeyWindow: true
        )

        assertSnapshot(of: viewController, as: strategy, named: testCase.label)
    }
}

private extension UpsellType {
    var label: String {
        switch self {
        case .mailPlus:
            "mailPlus"
        case .unlimited:
            "unlimited"
        }
    }
}
