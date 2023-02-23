// Copyright (c) 2022 Proton Technologies AG
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

import UIKit

/// This view will passing the touch event to the parent view if the location of the touch is inside the target frame.
class TouchPassingThroughTargetView: UIView {
    var passThroughFrame: CGRect?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let passThroughFrame = passThroughFrame,
              event?.type == .touches else {
            return
        }
        touches.forEach { touch in
            let location = touch.preciseLocation(in: self)
            if passThroughFrame.contains(location) {
                guard let topVC = findTopViewControllerInNavigationView() else {
                    next?.touchesBegan(touches, with: event)
                    return
                }

                let point = touch.location(in: topVC.view)
                if let buttonInTopVC = topVC.view.hitTest(point, with: event) as? UIControl {
                    // Check if the touch is inside topVC of the navigation view.
                    buttonInTopVC.sendActions(for: .touchUpInside)
                } else if let subviewsInNav = topVC.navigationController?.view.subviews.filter({ $0 != self }) {
                    // Check if the touch is inside the navigation view.
                    subviewsInNav.forEach { view in
                        let subPoint = touch.location(in: view)
                        if let view = view.hitTest(subPoint, with: event) as? UIControl {
                            view.sendActions(for: .touchUpInside)
                        }
                    }
                }
            }
        }
    }

    private func findTopViewControllerInNavigationView() -> UIViewController? {
        var responder = self.next
        while responder != nil && !(responder is UINavigationController) {
            responder = responder?.next
        }
        guard let nav = responder as? UINavigationController else {
            return nil
        }
        return nav.topViewController
    }
}
