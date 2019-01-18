//
//  2FACodeView.swift
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

protocol TwoFACodeViewDelegate {
    func ConfirmedCode(_ code : String, pwd : String)
    func Cancel()
}


enum AuthMode : Int
{
    case loginPassword =      0x01
    case twoFactorCode =      0x02
    case pwdAnd2FA = 0x03   // LoginPassword | TwoFactorCode
    
    func check(_ check: AuthMode) -> Bool {
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
    
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var enterButton: UIButton!
    
    func initViewMode(_ mode : AuthMode) {
        self.mode = mode
        
        if mode.check(.loginPassword) {
            pwdTop.constant = 18.0
            pwdHeight.constant = 40.0
        } else {
            pwdTop.constant = 0.0
            pwdHeight.constant = 0.0
        }
        
        if mode.check(.twoFactorCode) {
            twofacodeTop.constant = 18.0
            twofacodeHeight.constant = 40.0
        } else {
            twofacodeTop.constant = 0.0
            twofacodeHeight.constant = 0.0
        }
        
        let toolbarDone = UIToolbar.init()
        toolbarDone.sizeToFit()
        let barBtnDone = UIBarButtonItem.init(title: LocalString._recovery_code,
                                              style: UIBarButtonItem.Style.done,
                                              target: self,
                                              action: #selector(TwoFACodeView.doneButtonAction))
        toolbarDone.items = [barBtnDone]
        twoFactorCodeField.inputAccessoryView = toolbarDone
        
        twoFactorCodeField.placeholder = LocalString._two_factor_code
        loginPasswordField.placeholder = LocalString._login_password
        topTitleLabel.text = LocalString._authentication
        cancelButton.setTitle(LocalString._general_cancel_button, for: .normal)
        enterButton.setTitle(LocalString._enter, for: .normal)
    }

    @objc func doneButtonAction() {
        self.twoFactorCodeField.inputAccessoryView = nil
        self.twoFactorCodeField.keyboardType = UIKeyboardType.asciiCapable
        self.twoFactorCodeField.reloadInputViews()
    }
    
    override func getNibName() -> String {
        return "TwoFACodeView";
    }
    
    override func setup() {
        
    }
    
    func showKeyboard() {
        if mode!.check(.loginPassword) {
            loginPasswordField.becomeFirstResponder()
        } else if mode!.check(.twoFactorCode) {
            twoFactorCodeField.becomeFirstResponder()
        }
    }
    
    func confirm() {
        let pwd = (loginPasswordField.text ?? "")
        let code = (twoFactorCodeField.text ?? "").trim()
        if mode!.check(.loginPassword) {
            //error need
        }
        if mode!.check(.twoFactorCode) {
            //error need
        }
        
        self.dismissKeyboard()
        delegate?.ConfirmedCode(code, pwd: pwd)
    }
    
    @IBAction func enterAction(_ sender: AnyObject) {
        self.confirm()
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        self.dismissKeyboard()
        delegate?.Cancel()
    }
    
    func dismissKeyboard() {
        twoFactorCodeField.resignFirstResponder()
        loginPasswordField.resignFirstResponder()
    }
}

