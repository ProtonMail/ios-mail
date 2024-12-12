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

import InboxCore
@testable import InboxCoreUI
import InboxSnapshotTesting
import InboxTesting
import XCTest

class ToastSceneViewSnapshotTests: BaseTestCase {

    var store: ToastStateStore!
    var workItems: [DispatchWorkItem]!

    override func setUp() {
        super.setUp()
        store = .init(initialState: .initial)
        workItems = []
        Dispatcher.dispatchOnMainAfter = { _, workItem in
            self.workItems.append(workItem)
        }
    }

    override func tearDown() {
        store = nil
        workItems = nil
        super.tearDown()
    }

    func testToastSceneViewWithoutToastsLayoutsCorrectly() {
        let toastSceneView = ToastSceneView().environmentObject(store)

        assertSnapshotsOnIPhoneX(of: toastSceneView)
    }

    func testToastSceneViewWithOneToastPresentedTwiceLayoutsCorrectly() {
        let toastSceneView = ToastSceneView().environmentObject(store)

        store.present(toast: ToastViewPreviewProvider.smallSuccessLongTextWithButton)
        store.present(toast: ToastViewPreviewProvider.smallSuccessLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView)
    }

    func testToastSceneViewWithFourToastsLayoutsCorrectly() {
        let toastSceneView = ToastSceneView().environmentObject(store)

        let duplicatedToast = ToastViewPreviewProvider.bigWarningShortTextWithButton

        store.present(toast: ToastViewPreviewProvider.smallInformationLongTextWithButton)
        store.present(toast: duplicatedToast)
        store.present(toast: ToastViewPreviewProvider.bigSuccessLongTextWithButton)
        store.present(toast: duplicatedToast)
        store.present(toast: ToastViewPreviewProvider.bigErrorMaxLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView)
    }

    func testToastSceneViewWithThreeToastsLayoutsCorrectly() throws {
        let toastSceneView = ToastSceneView().environmentObject(store)

        store.present(toast: ToastViewPreviewProvider.smallInformationLongTextWithButton)
        store.present(toast: ToastViewPreviewProvider.bigErrorShortTextWithButton)
        store.present(toast: ToastViewPreviewProvider.bigSuccessLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "3_toasts_initial")

        workItems.first?.perform()

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "2_toasts_4_seconds_elapsed")

        store.dismiss(toast: ToastViewPreviewProvider.bigErrorShortTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "1_toast_manual_dismissal")

        store.dismiss(toast: ToastViewPreviewProvider.bigSuccessLongTextWithButton)

        assertSnapshotsOnIPhoneX(of: toastSceneView, named: "0_toasts_manual_dismissal")
    }

}
