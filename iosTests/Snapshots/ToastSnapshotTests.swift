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
import DesignSystem
import SnapshotTesting
import SwiftUI
import XCTest

class ToastViewSnapshotTests: XCTestCase {

    func testSmallWarningToastShortTextNoActionLayoutsCorrecttly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallWarningShortTextNoAction)
        assertSnapshot(of: UIHostingController(rootView: toastView), as: .image(on: .iPhoneX))
    }

    func testSmallErrorToastLongTextNoActionLayoutsCorrecttly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallErrorLongTextNoAction)
        assertSnapshot(of: UIHostingController(rootView: toastView), as: .image(on: .iPhoneX))
    }

    func testSmallInformationToastLongTextImageButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallInformationLongTextWithButton)
        assertSnapshot(of: UIHostingController(rootView: toastView), as: .image(on: .iPhoneX))
    }

    func testSmallSuccessToastLongTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.smallSuccessLongTextWithButton)
        assertSnapshot(of: UIHostingController(rootView: toastView), as: .image(on: .iPhoneX))
    }

    func testBigErrorToastShortTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.bigErrorShortTextWithButton)
        assertSnapshot(of: UIHostingController(rootView: toastView), as: .image(on: .iPhoneX))
    }

    func testBigErrorToastMaxLongTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.bigErrorMaxLongTextWithButton)
        assertSnapshot(of: UIHostingController(rootView: toastView), as: .image(on: .iPhoneX))
    }

    func testBigSuccessToastLongTextTitleButtonLayoutsCorrectly() {
        let toastView = ToastView(model: ToastViewPreviewProvider.bigSuccessLongTextWithButton)
        assertSnapshot(of: UIHostingController(rootView: toastView), as: .image(on: .iPhoneX))
    }

}
