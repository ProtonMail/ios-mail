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
import InboxSnapshotTesting
import SwiftUI
import XCTest

final class CyclingProgressBarSnapshotTests: XCTestCase {
    func testAllAnimationPhases() {
        assertSnapshotsOnIPhoneX(of: CyclingProgressBarAllPhases())
    }
}

private struct CyclingProgressBarAllPhases: View {
    private let phases: [CGFloat] = stride(from: 0.0, through: 1.0, by: 0.05).map { $0 }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ForEach(phases, id: \.self) { phase in
                VStack(alignment: .leading) {
                    Text("\(Int(phase * 100))% of animation")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)

                    CyclingProgressBar(animationPhase: phase)
                }
            }
        }
    }
}
