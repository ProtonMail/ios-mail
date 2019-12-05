//
//  ShowImageView.swift
//  ProtonMail - Created on 3/22/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


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
        messageLabel.sizeToFit()
        var size = self.frame.size
        size.width -= 40
        let s = messageLabel.sizeThatFits(size)
        return s.height + 16
    }
    
    override func setup() {
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.sizeToFit()
        messageLabel.text = ""
    }
}
