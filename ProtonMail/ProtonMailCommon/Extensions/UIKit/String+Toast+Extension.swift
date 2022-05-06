//
//  String+Toast+Extension.swift
//  Proton Mail - Created on 7/31/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import MBProgressHUD
import UIKit

extension String {
    /// Pass view to this function if you want to show alert in extension
    /// - Parameter withTitle: Should attach a default title yes/no
    /// - Parameter view: The `view` to use as the spawn point
    /// - Parameter preventCopies: Prevents multiple copies of previous huds on the same `view` yes/no
    func alertToast(withTitle: Bool = true, view: UIView? = nil, preventCopies: Bool = false) {
        guard let view = determineSpawnView(for: view) else {
            return
        }
        if preventCopies, MBProgressHUD(for: view) != nil {
            // We are showing an alert already, no-op
            return
        }

        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        if withTitle {
            hud.label.text = LocalString._general_alert_title
        }
        hud.detailsLabel.text = self
        let offset = self.getOffset(view: view, hud: hud)
        hud.offset = CGPoint(x: 0, y: offset)
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }

    func alertToastBottom(view: UIView? = nil) {
        guard let view = determineSpawnView(for: view) else {
            return
        }
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        let offset = self.getOffset(view: view, hud: hud)
        hud.offset = CGPoint(x: 0, y: 250 + offset)
        hud.hide(animated: true, afterDelay: 1)
    }

    func alertToastBottom(view: UIView? = nil, subtitle: String) {
        guard let view = determineSpawnView(for: view) else {
            return
        }
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = self
        hud.detailsLabel.text = subtitle
        let offset = subtitle.getOffset(view: view, hud: hud)
        hud.offset = CGPoint(x: 0, y: offset)
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }

    private func determineSpawnView(for view: UIView?) -> UIView? {
        var viewToShow: UIView?
        #if APP_EXTENSION
        viewToShow = view
        #else
        let application = UIApplication.shared
        viewToShow = application.keyWindow
        #endif
        return viewToShow
    }

    /**
     show toast message at top of the view
     
     - Parameter view: will show the toast message on top of this view
     
     - Returns: void
     **/
    func toast(at view: UIView) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = LocalString._general_alert_title
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }

    private func getOffset(view: UIView, hud: MBProgressHUD) -> CGFloat {
        var previousHUDs = view.subviews
            .filter { $0 is MBProgressHUD && $0 != hud }
        guard previousHUDs.count > 0 else { return 0 }

        hud.layoutIfNeeded()
        previousHUDs.forEach { $0.layoutIfNeeded() }

        previousHUDs.sort { hud1, hud2 in
            guard let backView1 = hud1.subviews
                    .first(where: { $0.subviews.count > 0 }),
                  let backView2 = hud2.subviews
                    .first(where: { $0.subviews.count > 0 }) else {
                return false
            }
            return backView1.frame.origin.y <= backView2.frame.origin.y
        }

        guard let newBackView = hud.subviews
                .first(where: { $0.subviews.count > 0 }),
              let lastHud = previousHUDs.last,
              let lastBackView = lastHud.subviews
                .first(where: { $0.subviews.count > 0 }) else {
            return 0
        }
        let newHeight = newBackView.frame.size.height
        let lastHeight = lastBackView.frame.size.height

        var offset: CGFloat = 0 - newHeight / 2 - lastHeight / 2
        let padding: CGFloat = 10
        if previousHUDs.count > 1 {
            previousHUDs.removeLast()
            previousHUDs.forEach { hudView in
                guard let backView = hudView.subviews.first(where: { $0.subviews.count > 0 }) else { return }
                offset -= backView.frame.size.height
            }
            offset -= CGFloat(previousHUDs.count + 1) * padding
        } else {
            offset -= padding
        }
        return offset
    }
}
