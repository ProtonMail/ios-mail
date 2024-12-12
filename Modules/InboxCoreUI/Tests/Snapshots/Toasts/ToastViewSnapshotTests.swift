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

@testable import InboxCoreUI
import InboxTesting
import XCTest

class ToastViewSnapshotTests: BaseTestCase {

    func testSmallWarningToastShortTextNoActionLayoutsCorrecttly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallWarningShortTextNoAction, didSwipeDown: {})
        assertSnapshotsOnIPhoneX(of: toastView)
    }

    func testSmallErrorToastLongTextNoActionLayoutsCorrecttly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallErrorLongTextNoAction, didSwipeDown: {})
        assertSnapshotsOnIPhoneX(of: toastView)
    }

    func testSmallInformationToastLongTextImageButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallInformationLongTextWithButton, didSwipeDown: {})
        assertSnapshotsOnIPhoneX(of: toastView)
    }

    func testSmallSuccessToastLongTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallSuccessLongTextWithButton, didSwipeDown: {})
        assertSnapshotsOnIPhoneX(of: toastView)
    }

    func testBigErrorToastShortTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.bigErrorShortTextWithButton, didSwipeDown: {})
        assertSnapshotsOnIPhoneX(of: toastView)
    }

    func testBigErrorToastMaxLongTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.bigErrorMaxLongTextWithButton, didSwipeDown: {})
        assertSnapshotsOnIPhoneX(of: toastView)
    }

    func testBigSuccessToastLongTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.bigSuccessLongTextWithButton, didSwipeDown: {})
        assertSnapshotsOnIPhoneX(of: toastView)
    }

}
