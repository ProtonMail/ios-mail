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

@testable import ProtonUIFoundations
import Dispatch
import InboxCore
import InboxCoreUI
import InboxSnapshotTesting
import InboxTesting
import SwiftUICore
import Testing

@MainActor
final class ToastSceneViewSnapshotTests {
    private let store = ToastStateStore(initialState: .initial)

    @Test
    func testToastSceneViewWithoutToastsLayoutsCorrectly() {
        let toastSceneView = makeSUT()

        assertSnapshotsOnIPhoneX(of: toastSceneView)
    }

    @Test
    func testToastSceneViewWithOneToastPresentedTwiceLayoutsCorrectly() {
        let toastSceneView = makeSUT()

        store.present(toast: ToastViewPreviewProvider.smallSuccessLongTextWithButton)
        store.present(toast: ToastViewPreviewProvider.smallSuccessLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView)
    }

    @Test
    func testToastSceneViewWithFourToastsLayoutsCorrectly() {
        let toastSceneView = makeSUT()

        let duplicatedToast = ToastViewPreviewProvider.bigWarningShortTextWithButton

        store.present(toast: ToastViewPreviewProvider.smallInformationLongTextWithButton)
        store.present(toast: duplicatedToast)
        store.present(toast: ToastViewPreviewProvider.bigSuccessLongTextWithButton)
        store.present(toast: duplicatedToast)
        store.present(toast: ToastViewPreviewProvider.bigErrorMaxLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView)
    }

    @Test
    func testToastSceneViewWithThreeToastsLayoutsCorrectly() throws {
        var workItems: [DispatchWorkItem] = []

        Dispatcher.dispatchOnMainAfter = { _, workItem in
            workItems.append(workItem)
        }

        let toastSceneView = makeSUT()

        store.present(toast: ToastViewPreviewProvider.smallInformationLongTextWithButton)
        store.present(toast: ToastViewPreviewProvider.bigErrorShortTextWithButton)
        store.present(toast: ToastViewPreviewProvider.bigSuccessLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "3_toasts_initial")

        workItems[0].perform()

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "2_toasts_4_seconds_elapsed")

        store.dismiss(toast: ToastViewPreviewProvider.bigErrorShortTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "1_toast_manual_dismissal")

        store.dismiss(toast: ToastViewPreviewProvider.bigSuccessLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "0_toasts_manual_dismissal")
    }

    private func makeSUT() -> some View {
        ToastSceneView(dispatchAfter: Dispatcher.dispatchOnMainAfter).environmentObject(store)
    }
}
