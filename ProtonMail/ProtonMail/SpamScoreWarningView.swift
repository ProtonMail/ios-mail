//
//  ShowImageView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/22/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

class SpamScoreWarningView: PMView {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    override func getNibName() -> String {
        return "SpamScoreWarningView"
    }
    
    func setMessage(msg : String) {
        messageLabel.text = msg
    }
    
    func fitHeight() -> CGFloat {
        let s = messageLabel.sizeThatFits(self.frame.size)
        return s.height + 16
    }
    
    override func setup() {
        messageLabel.numberOfLines = 0
        messageLabel.sizeToFit()
        messageLabel.text = ""
    }
}
