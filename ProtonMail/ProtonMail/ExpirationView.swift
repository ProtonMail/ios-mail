//
//  ExpirationView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/22/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation



class ExpirationView: PMView {
    override func getNibName() -> String {
        return "ExpirationView"
    }
    
    @IBOutlet weak var expirationLabel: UILabel!
    
    func setExpirationTime(_ offset : Int) {
        let (d,h,m,s) = durationsBySecond(seconds: offset)
        if offset <= 0 {
            expirationLabel.text = NSLocalizedString("Message expired", comment: "")
        } else {
            expirationLabel.text = String(format: NSLocalizedString("Expires in %d days %d hours %d mins %d seconds", comment: "expiration time count down"), d, h, m, s)
        }
    }
    
    func durationsBySecond(seconds s: Int) -> (days:Int,hours:Int,minutes:Int,seconds:Int) {
        return (s / (24 * 3600),(s % (24 * 3600)) / 3600, s % 3600 / 60, s % 60)
    }
}
