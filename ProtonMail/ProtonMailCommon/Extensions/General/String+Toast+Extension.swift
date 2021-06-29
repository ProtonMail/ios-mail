//
//  String+Toast+Extension.swift
//  ProtonMail - Created on 7/31/17.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import MBProgressHUD

extension String {
    
    // Pass view to this function if you want to show alert in extension
    public func alertToast(withTitle: Bool = true, view: UIView? = nil) -> Void {
        var viewToShow: UIView?

        #if APP_EXTENSION
        viewToShow = view
        #else
        viewToShow = UIApplication.shared.keyWindow
        #endif
        
        guard let view = viewToShow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: view, animated: true)
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
    
    public func alertToastBottom(view: UIView? = nil) ->Void {
        var viewToShow: UIView?

        #if APP_EXTENSION
        viewToShow = view
        #else
        viewToShow = UIApplication.shared.keyWindow
        #endif
        
        guard let view = viewToShow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        let offset = self.getOffset(view: view, hud: hud)
        hud.offset = CGPoint(x: 0, y: 250 + offset)
        hud.hide(animated: true, afterDelay: 1)
    }
    
    /**
     show toast message at top of the view
     
     - Parameter view: will show the toast message on top of this view
     
     - Returns: void
     **/
    func toast(at view: UIView) -> Void {
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: view, animated: true)
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
