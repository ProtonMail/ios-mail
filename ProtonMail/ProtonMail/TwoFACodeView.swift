//
//  2FACodeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

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
        let barBtnDone = UIBarButtonItem.init(title: NSLocalizedString("Recovery Code", comment: "Title"),
                                              style: UIBarButtonItemStyle.done,
                                              target: self,
                                              action: #selector(TwoFACodeView.doneButtonAction))
        toolbarDone.items = [barBtnDone]
        twoFactorCodeField.inputAccessoryView = toolbarDone
        
        twoFactorCodeField.placeholder = NSLocalizedString("Two Factor Code", comment: "Placeholder")
        loginPasswordField.placeholder = NSLocalizedString("Login Password", comment: "Placeholder")
        topTitleLabel.text = NSLocalizedString("Authentication", comment: "Title")
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Action"), for: .normal)
        enterButton.setTitle(NSLocalizedString("Enter", comment: "Action"), for: .normal)
    }

    func doneButtonAction() {
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

