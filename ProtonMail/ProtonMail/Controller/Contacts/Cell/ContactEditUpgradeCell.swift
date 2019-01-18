//
//  ContactEditUpgradeCell.swift
//  ProtonMail - Created on 1/8/18.
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

final class ContactEditUpgradeCell : UITableViewCell {
    
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var upgradeButton: UIButton!
    
    //fileprivate let upgradePageUrl = URL(string: "https://protonmail.com/upgrade")!
    private var delegate:ContactUpgradeCellDelegate?
    
    override func awakeFromNib() {
        let color = UIColor(hexColorCode: "#9497CE")
        frameView.layer.borderColor = color.cgColor
        frameView.layer.borderWidth = 1.0
        frameView.layer.cornerRadius = 4.0
        frameView.clipsToBounds = true
        upgradeButton.roundCorners()
    }
    
    @IBAction func upgradeAction(_ sender: Any) {
        self.delegate?.upgrade()
    }
    
    func configCell(delegate: ContactUpgradeCellDelegate?) {
        self.delegate = delegate
    }
}
