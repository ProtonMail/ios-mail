//
//  2FACodeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

protocol TwoFACodeViewDelegate {
    func ConfirmedCode(code : String)
    func Cancel()
}

class TwoFACodeView : PMView {
    
    var delegate : TwoFACodeViewDelegate?
    
    @IBOutlet weak var twoFactorCodeField: TextInsetTextField!
    @IBOutlet weak var loginPasswordField: TextInsetTextField!
    
    override func getNibName() -> String {
        return "TwoFACodeView";
    }
    
    override func setup() {
        
    }
    
    func showKeyboard() {
        loginPasswordField.resignFirstResponder()
    }
    
    @IBAction func enterAction(sender: UIButton) {
        self.dismissKeyboard()
        delegate?.ConfirmedCode("123")
    }
    
    @IBAction func cancelAction(sender: UIButton) {
        self.dismissKeyboard()
        delegate?.Cancel()
    }
    
    
    func dismissKeyboard() {
        twoFactorCodeField.resignFirstResponder()
        loginPasswordField.resignFirstResponder()
    }
}

