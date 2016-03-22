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
    
    
    
    func setExpirationTime(offset : Int) {
        let (d,h,m,s) = durationsBySecond(seconds: offset)
        println()
        if offset <= 0 {
            expirationLabel.text = "Message expired"
        } else {
            expirationLabel.text = "Expires in \(d) days \(h) hours \(m) mins \(s) seconds"
        }
    }
    
    func durationsBySecond(seconds s: Int) -> (days:Int,hours:Int,minutes:Int,seconds:Int) {
        return (s / (24 * 3600),(s % (24 * 3600)) / 3600, s % 3600 / 60, s % 60)
    }
}