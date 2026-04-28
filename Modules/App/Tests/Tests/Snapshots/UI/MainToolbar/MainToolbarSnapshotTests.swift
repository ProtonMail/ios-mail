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

import InboxDesignSystem
import InboxIAP
import InboxSnapshotTesting
import InboxTesting
import ProtonUIFoundations
import SwiftUI
import Testing
import UIKit
import proton_app_uniffi

@testable import ProtonMail

@MainActor
final class MainToolbarSnapshotTests {
    @Test(arguments: [UIUserInterfaceStyle.light, .dark], [UpsellType.mailPlus, .unlimited])
    func mainToolbarWithUpsell(style: UIUserInterfaceStyle, upsellType: UpsellType) {
        let view = makeToolbarView(upsellEligibility: .eligible(upsellType))
        assertSnapshotsOnIPhoneX(
            of: view,
            named: "upsellType.\(upsellType)",
            styles: [style],
            drawHierarchyInKeyWindow: true,
            precision: 0.99
        )
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func mainToolbarWithoutUpsell(style: UIUserInterfaceStyle) {
        let view = makeToolbarView(upsellEligibility: .notEligible)
        assertSnapshotsOnIPhoneX(of: view, styles: [style], drawHierarchyInKeyWindow: true)
    }

    private func makeToolbarView(upsellEligibility: UpsellEligibility) -> some View {
        NavigationStack {
            Color.clear
                .mainToolbar(
                    title: "Inbox",
                    onEvent: { _ in },
                    avatarView: {
                        Text("R")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.white)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius.large))
                    }
                )
        }
        .environment(\.upsellEligibility, upsellEligibility)
        .environmentObject(ToastStateStore(initialState: .initial))
        .environmentObject(UpsellCoordinator.dummy)
    }
}
