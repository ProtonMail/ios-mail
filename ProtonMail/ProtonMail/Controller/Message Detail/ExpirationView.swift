//
//  ExpirationView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/22/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


@IBDesignable
class ExpirationView: PMView {
    override func getNibName() -> String {
        return "ExpirationView"
    }
    
    @IBOutlet weak var expirationLabel: UILabel!
    
    func setExpirationTime(_ offset : Int) {
        let (d,h,m,s) = durationsBySecond(seconds: offset)
        if offset <= 0 {
            expirationLabel.text = LocalString._message_expired
        } else {
            expirationLabel.text = String(format: LocalString._expires_in_days_hours_mins_seconds, d, h, m, s)
        }
    }
    
    func durationsBySecond(seconds s: Int) -> (days:Int,hours:Int,minutes:Int,seconds:Int) {
        return (s / (24 * 3600),(s % (24 * 3600)) / 3600, s % 3600 / 60, s % 60)
    }
}
