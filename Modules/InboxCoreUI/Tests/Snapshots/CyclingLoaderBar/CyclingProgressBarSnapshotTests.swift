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

@testable import InboxCoreUI
import InboxDesignSystem
import InboxSnapshotTesting
import InboxTesting
import XCTest

final class CyclingProgressBarSnapshotTests: XCTestCase {
    func testProgressBar_atDifferentPhases() {
        let phases: [String: CGFloat] = [
            "0_percent": 0,
            "10_percent": 0.10,
            "20_percent": 0.20,
            "30_percent": 0.30,
            "40_percent": 0.40,
            "50_percent": 0.50,
            "60_percent": 0.60,
            "70_percent": 0.70,
            "80_percent": 0.80,
            "90_percent": 0.90,
            "100_percent": 1.00,
        ]

        for (name, phase) in phases {
            assertSnapshotsOnIPhoneX(of: CyclingProgressBar(animationPhase: phase), named: name)
        }
    }
}
