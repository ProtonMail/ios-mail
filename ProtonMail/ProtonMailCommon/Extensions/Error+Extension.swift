//
//  Error+Extension.swift
//  ProtonMail - Created on 2018/10/23.
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
import ProtonCore_Common

extension Error
{
    func alertToast() ->Void {
        guard !(self as NSError).isBadVersionError else { return }
        MBProgressHUD.alertToast(errorString: localizedDescription)
    }
    
    func alert(at view: UIView) ->Void {
        guard !(self as NSError).isBadVersionError else { return }
        MBProgressHUD.alert(at: view, errorString: localizedDescription)
    }
    
    //    func alertController() -> UIAlertController {
    
    //        let message = self.localizedDescription
    // var title = self.localizedTitle
    
    //        var message = self.localizedFailureReason
    
    //        if localizedRecoverySuggestion != nil {
    //            if message != nil {
    //                message = message! + "\n\n"
    //            } else {
    //                message = ""
    //            }
    //
    //            message = message! + localizedRecoverySuggestion!
    //        }
    //        return UIAlertController(title: message /*localizedDescription*/, message: message, preferredStyle: .alert)
    //    }
}
