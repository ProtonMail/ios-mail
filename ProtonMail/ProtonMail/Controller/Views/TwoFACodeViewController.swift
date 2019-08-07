//
//  TwoFACodeViewController.swift
//  ProtonMail - Created on 11/3/16.
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
import UIKit

protocol TwoFACodeViewControllerDelegate {
    func Cancel2FA()
    func ConfirmedCode(_ code : String, pwd:String)
}

class TwoFACodeViewController : UIViewController {
    //var viewModel : TwoFAViewModel!
    @IBOutlet weak var twoFACodeView: TwoFACodeView!
    var delegate : TwoFACodeViewControllerDelegate?
    
    var mode : AuthMode!
    
    @IBOutlet weak var tfaCodeCenterConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.twoFACodeView.delegate = self
        self.twoFACodeView.layer.cornerRadius = 8;
        self.twoFACodeView.initViewMode(mode)
        self.twoFACodeView.showKeyboard()
        
        // we want the code to be pasted only when user comes back after switching to authenticator app
        var notificationName = UIApplication.willEnterForegroundNotification
        if #available(iOS 13.0, *) {
            notificationName = UIScene.willEnterForegroundNotification
        }
        
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { [weak self] _ in
            self?.twoFACodeView.fill2FACodeFromPasteboard()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension TwoFACodeViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        tfaCodeCenterConstraint.constant = 0.0
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tfaCodeCenterConstraint.constant = (keyboardSize.height / 2) * -1.0
        }
    }
}


extension TwoFACodeViewController : TwoFACodeViewDelegate {

    func ConfirmedCode(_ code: String, pwd : String) {
        delegate?.ConfirmedCode(code, pwd:pwd)
        self.dismiss(animated: true, completion: nil)
    }
    
    func Cancel() {
        delegate?.Cancel2FA()
        self.dismiss(animated: true, completion: nil)
    }
}
