// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
@testable import ProtonMail
import UIKit

final class NewMessageBodyViewModelDelegateMock: NewMessageBodyViewModelDelegate {
    enum UserInterfaceStyle: Int {
        case unspecified = 0
        case light = 1
        case dark = 2
    }

    var interfaceStyle: UserInterfaceStyle = .unspecified
    var isApplyDarkStyle: Bool?

    @available(iOS 12.0, *)
    func getUserInterfaceStyle() -> UIUserInterfaceStyle {
        switch interfaceStyle {
        case .unspecified:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func sendDarkModeMetric(isApply: Bool) {
        isApplyDarkStyle = isApply
    }

    var isReloadWebViewCalled = false
    func reloadWebView(forceRecreate: Bool) {
        isReloadWebViewCalled = true
    }

    func showReloadError() {}

    func updateBannerStatus() {}

    func showDecryptionErrorBanner() {}

    func hideDecryptionErrorBanner() {}
}
