// Copyright (c) 2023 Proton Technologies AG
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

import Foundation
import ProtonCoreUIFoundations
import UIKit

extension PMBanner {

    static func showProtonUnreachable(on viewController: UIViewController) {
        let banner = PMBanner(
            message: LocalString._general_proton_unreachable,
            style: PMBannerNewStyle.error,
            dismissDuration: 10.0,
            bannerHandler: PMBanner.dismiss
        )
        banner.addButton(icon: IconProvider.arrowOutSquare) { _ in
            banner.dismiss()
            if let url = URL(string: Link.protonStatusPage) {
                UIApplication.shared.open(url)
            } else {
                PMAssertionFailure("Invaild status page link")
            }
        }
        banner.show(at: .top, on: viewController)
        Analytics.shared.sendEvent(.protonUnreachableBannerShown)
    }
}
