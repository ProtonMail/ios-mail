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
    }
    
    
    func setCorner(button : UIButton) {
        
        let w = oneButton.frame.size.width
        button.layer.cornerRadius = w/2
        button.clipsToBounds = true
        
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.layer.borderWidth = 1.0
    }
}