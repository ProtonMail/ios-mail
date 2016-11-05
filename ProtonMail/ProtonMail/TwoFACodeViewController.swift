//
//  TwoFACodeViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

protocol TwoFACodeViewControllerDelegate {
    func Cancel2FA()
    func ConfirmedCode(code : String, pwd:String)
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension TwoFACodeViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        tfaCodeCenterConstraint.constant = 0.0
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let info: NSDictionary = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            tfaCodeCenterConstraint.constant = (keyboardSize.height / 2) * -1.0
        }
    }
}


extension TwoFACodeViewController : TwoFACodeViewDelegate {

    func ConfirmedCode(code: String, pwd : String) {
        delegate?.ConfirmedCode(code, pwd:pwd)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func Cancel() {
        delegate?.Cancel2FA()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
