//
//  String+Toast+Extension.swift
//  ProtonMail - Created on 7/31/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import MBProgressHUD

extension String {
    
    public func alertToast() -> Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = LocalString._general_alert_title
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }
    
    public func alertToastBottom() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
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
    
}
