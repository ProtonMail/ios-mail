//
//  Error+Extension.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/23.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import MBProgressHUD

extension Error
{
    func alertToast() ->Void {
        MBProgressHUD.alertToast(errorString: localizedDescription)
    }
    
    func alert(at view: UIView) ->Void {
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
