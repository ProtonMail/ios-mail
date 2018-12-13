//
//  MessageDetailBottomView.swift
//  ProtonMail - Created on 5/11/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
