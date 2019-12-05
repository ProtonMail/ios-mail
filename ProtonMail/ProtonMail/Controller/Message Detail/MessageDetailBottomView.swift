//
//  MessageDetailBottomView.swift
//  ProtonMail - Created on 5/11/15.
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


import UIKit

protocol MessageDetailBottomViewDelegate : AnyObject {
    func replyAction()
    func replyAllAction()
    func forwardAction()
}

class MessageDetailBottomView: PMView {

    weak var delegate: MessageDetailBottomViewDelegate?
    
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var replyAllButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    override func getNibName() -> String {
        return "MessageDetailBottomView"
    }
    
    override func setup() {
        self.replyButton.setTitle(LocalString._general_reply_button, for: .normal)
        self.replyAllButton.setTitle(LocalString._general_replyall_button, for: .normal)
        self.forwardButton.setTitle(LocalString._general_forward_button, for: .normal)
    }
    
    @IBAction func replyClicked(_ sender: AnyObject) {
        self.delegate?.replyAction()
    }
    
    @IBAction func replyAllClicked(_ sender: AnyObject) {
        self.delegate?.replyAllAction()
    }
    
    @IBAction func forwardClicked(_ sender: AnyObject) {
        self.delegate?.forwardAction()
    }
}
