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

@testable import ProtonMail
import InboxCoreUI
import InboxSnapshotTesting
import SwiftUI
import Testing

@MainActor
final class MoveToSheetSnapshotTests {
    @Test
    func actionSheetLayoutsCorrectly() async {
        var moveToSheet = MoveToSheet(
            input: .init(sheetType: .moveTo, ids: [], mailboxItem: .message(isLastMessageInCurrentLocation: false)),
            mailbox: .dummy,
            availableMoveToActions: MoveToSheetPreviewProvider.availableMoveToActions,
            moveToActions: .dummy,
            navigation: { _ in },
            mailUserSession: .dummy)

        for style in [UIUserInterfaceStyle.light, .dark] {
            let viewController = await renderAndWait { continuation in
                moveToSheet.didLoad = continuation.resume
                return moveToSheet.environmentObject(ToastStateStore(initialState: .initial))
            }

            viewController.overrideUserInterfaceStyle = style
            assertSnapshotOnIPhoneX(of: viewController, style: style, named: "move_to_sheet")
        }
    }

    private func renderAndWait<Content: View>(contentBuilder: (CheckedContinuation<Void, Never>) -> Content) async -> UIViewController {
        var viewController: UIViewController!

        await withCheckedContinuation { continuation in
            let sut = contentBuilder(continuation)
            viewController = UIHostingController(rootView: sut)
            viewController.view.snapshotView(afterScreenUpdates: true)
        }

        return viewController
    }
}
