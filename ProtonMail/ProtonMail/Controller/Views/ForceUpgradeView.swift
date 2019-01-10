//
//  ForceUpgradeView.swift
//  ProtonMail - Created on 09/11/18.
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


import Foundation

protocol ForceUpgradeViewDelegate : AnyObject {
    func learnMore()
    func update()
}

class ForceUpgradeView : PMView {
    weak var delegate : ForceUpgradeViewDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    
    override func getNibName() -> String {
        return "ForceUpgradeView"
    }

    override func setup() {
        //set localized strings
        self.titleLabel.text = LocalString._update_required
        self.learnMoreButton.setTitle(LocalString._learn_more, for: .normal)
        self.updateButton.setTitle(LocalString._update_now, for: .normal)
    }

    @IBAction func updateAction(_ sender: AnyObject) {
        delegate?.update()
    }
    
    @IBAction func learnMoreAction(_ sender: AnyObject) {
        delegate?.learnMore()
    }
}

