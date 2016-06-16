//
//  PinCodeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/6/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation

protocol PinCodeViewDelegate {
    func Cancel()
    func Next(code : String)
    func TouchID()
}

class PinCodeView : PMView {
    
    @IBOutlet weak var oneButton: UIButton!
    @IBOutlet weak var twoButton: UIButton!
    @IBOutlet weak var threeButton: UIButton!
    @IBOutlet weak var fourButton: UIButton!
    @IBOutlet weak var fiveButton: UIButton!
    @IBOutlet weak var sixButton: UIButton!
    @IBOutlet weak var sevButton: UIButton!
    @IBOutlet weak var eightButton: UIButton!
    @IBOutlet weak var nineButton: UIButton!
    @IBOutlet weak var zeroButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    @IBOutlet weak var pinView: UIView!
    @IBOutlet weak var pinDisplayView: UITextField!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var touchIDButton: UIButton!
    
    @IBOutlet weak var attempsLabel: UILabel!
    @IBOutlet weak var whiteLineView: UIView!
    
    var delegate : PinCodeViewDelegate?
    
    var pinCode : String = ""
    
    override func getNibName() -> String {
        return "PinCodeView";
    }
    
    func showTouchID() {
        touchIDButton.hidden = false
    }
    
    func hideTouchID() {
        touchIDButton.hidden = true
    }
    
    override func setup() {
        touchIDButton.layer.cornerRadius = 25
        touchIDButton.hidden = true
    }
    
    func updateViewText(title : String, cancelText : String, resetPin : Bool) {
        titleLabel.text = title
        logoutButton.setTitle(cancelText, forState: UIControlState.Normal)
        if resetPin {
            self.resetPin()
        }
    }
    
    func updateTitle(title : String) {
        titleLabel.text = title
    }
    
    func updateCorner() {
        self.setCorner(oneButton)
        self.setCorner(twoButton)
        self.setCorner(threeButton)
        self.setCorner(fourButton)
        self.setCorner(fiveButton)
        self.setCorner(sixButton)
        self.setCorner(sevButton)
        self.setCorner(eightButton)
        self.setCorner(nineButton)
        self.setCorner(zeroButton)
        self.setCorner(goButton)
        
        logoutButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        logoutButton.titleLabel?.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        logoutButton.imageView?.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
    
    @IBAction func touchIDAction(sender: AnyObject) {
        delegate?.TouchID()
    }
    
    func showAttempError(error:String, low : Bool) {
        pinDisplayView.textColor = UIColor.redColor()
        whiteLineView.backgroundColor = UIColor.redColor()
        attempsLabel.hidden = false
        attempsLabel.text = error
        if low {
            attempsLabel.backgroundColor = UIColor.redColor()
            attempsLabel.textColor = UIColor.whiteColor()
        } else {
            attempsLabel.backgroundColor = UIColor.clearColor()
            attempsLabel.textColor = UIColor.redColor()
        }
    }
    
    func hideAttempError(reset : Bool) {
        pinDisplayView.textColor = UIColor.lightGrayColor()
        whiteLineView.backgroundColor = UIColor.whiteColor()
        if reset {
            attempsLabel.hidden = false
        }
    }
    
    internal func add(number : Int) {
        pinCode = pinCode + String(number)
        self.updateCodeDisplay()
    }
    
    internal func remove() {
        if !pinCode.isEmpty {
            pinCode =  pinCode.substringToIndex(pinCode.endIndex.predecessor())
            self.updateCodeDisplay()
        }
    }
    
    internal func resetPin() {
        pinCode = ""
        self.updateCodeDisplay()
    }
    
    internal func updateCodeDisplay() {
        pinDisplayView.text = pinCode
    }
    
    func showError() {
        pinView.shake(3, offset: 10)
    }
    
    func setCorner(button : UIView) {
        let w = button.frame.size.width
        button.layer.cornerRadius = w/2
        button.clipsToBounds = true
        
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.layer.borderWidth = 1.0
    }
    
    @IBAction func buttonActions(sender: UIButton) {
        self.hideAttempError(false)
        let numberClicked = sender.tag
        self.add(numberClicked)
    }
    
    @IBAction func deleteAction(sender: UIButton) {
        self.hideAttempError(false)
        self.remove()
    }
    
    @IBAction func logoutAction(sender: UIButton) {
        delegate?.Next(pinCode)
    }
    
    @IBAction func backAction(sender: UIButton) {
        delegate?.Cancel()
    }
    
    
    @IBAction func goAction(sender: UIButton) {
        delegate?.Next(pinCode)
    }
    
    internal func changePinStatus(pin : UIView, on : Bool) {
        if on {
            pin.backgroundColor = UIColor.lightGrayColor()
            pin.layer.borderWidth = 0.0
        } else {
            pin.backgroundColor = UIColor.clearColor()
            pin.layer.borderWidth = 1.0
        }
        
    }
    
}