//
//  PinCodeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/6/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation

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
    
    @IBOutlet weak var pinOne: UIImageView!
    @IBOutlet weak var pinTwo: UIImageView!
    @IBOutlet weak var pinThree: UIImageView!
    @IBOutlet weak var pinFour: UIImageView!
    
    @IBOutlet weak var pinView: UIView!
    override func getNibName() -> String {
        return "PinCodeView";
    }
    
    override func setup() {

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
        
        self.setCorner(pinOne)
        self.setCorner(pinTwo)
        self.setCorner(pinThree)
        self.setCorner(pinFour)
    }
    
    internal func resetPin() {
        
        self.changePinStatus(pinOne, on: false)
        self.changePinStatus(pinTwo, on: false)
        self.changePinStatus(pinThree, on: false)
        self.changePinStatus(pinFour, on: false)
        
    }
    
    func setCorner(button : UIView) {
        
        let w = button.frame.size.width
        button.layer.cornerRadius = w/2
        button.clipsToBounds = true
        
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.layer.borderWidth = 1.0
    }
    
    @IBAction func buttonActions(sender: UIButton) {
        pinView.shake(3, offset: 10)
        
        self.changePinStatus(pinOne, on: true)
    }
    
    @IBAction func logoutAction(sender: UIButton) {
        
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