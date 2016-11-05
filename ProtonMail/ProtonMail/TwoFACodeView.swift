//
//  2FACodeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

protocol TwoFACodeViewDelegate {
    func ConfirmedCode(code : String, pwd : String)
    func Cancel()
}


enum AuthMode : Int
{
    case LoginPassword =      0x01
    case TwoFactorCode =      0x02
    case PwdAnd2FA = 0x03   // LoginPassword | TwoFactorCode
    
    func check(check: AuthMode) -> Bool {
        if self.rawValue & check.rawValue == check.rawValue {
            return true
        }
        return false
    }
}

class TwoFACodeView : PMView {
    
    var delegate : TwoFACodeViewDelegate?
    var mode : AuthMode!
    
    @IBOutlet weak var pwdTop: NSLayoutConstraint! //18
    @IBOutlet weak var pwdHeight: NSLayoutConstraint! //40
    
    @IBOutlet weak var twofacodeTop: NSLayoutConstraint! //18
    @IBOutlet weak var twofacodeHeight: NSLayoutConstraint! //40
    
    @IBOutlet weak var twoFactorCodeField: TextInsetTextField!
    @IBOutlet weak var loginPasswordField: TextInsetTextField!
    
    func initViewMode(mode : AuthMode) {
        self.mode = mode
        
        if mode.check(.LoginPassword) {
            pwdTop.constant = 18.0
            pwdHeight.constant = 40.0
        } else {
            pwdTop.constant = 0.0
            pwdHeight.constant = 0.0
        }
        
        if mode.check(.TwoFactorCode) {
            twofacodeTop.constant = 18.0
            twofacodeHeight.constant = 40.0
        } else {
            twofacodeTop.constant = 0.0
            twofacodeHeight.constant = 0.0
        }
    }
    
    override func getNibName() -> String {
        return "TwoFACodeView";
    }
    
    override func setup() {
        
    }
    
    func showKeyboard() {
        if mode!.check(.LoginPassword) {
            loginPasswordField.becomeFirstResponder()
        } else if mode!.check(.TwoFactorCode) {
            twoFactorCodeField.becomeFirstResponder()
        }
    }
    
    @IBAction func enterAction(sender: AnyObject) {
        let pwd = (loginPasswordField.text ?? "")
        let code = (twoFactorCodeField.text ?? "").trim()
        if mode!.check(.LoginPassword) {
            //error need
        }
        if mode!.check(.TwoFactorCode) {
            //error need
        }
        
        self.dismissKeyboard()
        delegate?.ConfirmedCode(code, pwd: pwd)
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.dismissKeyboard()
        delegate?.Cancel()
    }
    
    func dismissKeyboard() {
        twoFactorCodeField.resignFirstResponder()
        loginPasswordField.resignFirstResponder()
    }
}

