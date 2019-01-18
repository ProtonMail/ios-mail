//
//  Error+Extension.swift
//  ProtonMail - Created on 2018/10/23.
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
