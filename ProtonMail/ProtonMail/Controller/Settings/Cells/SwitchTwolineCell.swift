//
//  SwitchTwolineCell.swift
//  ProtonMail - Created on 3/17/15.
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
import MessageUI



protocol SwitchTwolineCellDelegate {
    func mailto()
}

@IBDesignable class SwitchTwolineCell: UITableViewCell, UITextViewDelegate {
    typealias ActionStatus = (_ isOK: Bool) -> Void
    typealias switchActionBlock = (_ cell: SwitchTwolineCell?, _ newStatus: Bool, _ feedback: @escaping ActionStatus) -> Void

    
    var callback : switchActionBlock?
    var delegate : SwitchTwolineCellDelegate?
    
    @IBOutlet weak var topLineBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var topLineLabel: UILabel!
    
    @IBOutlet weak var bottomTextView: UITextView!
    @IBOutlet weak var switchView: UISwitch!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        topLineLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        topLineLabel.adjustsFontForContentSizeCategory = true
        
        bottomTextView.font = UIFont.preferredFont(forTextStyle: .caption1)
        bottomTextView.adjustsFontForContentSizeCategory = true
        
        bottomTextView.isSelectable = true
//        bottomTextView.delegate = self
        bottomTextView.sizeToFit()
    }
    
    @IBAction func switchAction(_ sender: UISwitch) {
        let status = sender.isOn
        callback?(self, status, { (isOK ) -> Void in
            if isOK == false {
                self.switchView.setOn(false, animated: true)
                self.layoutIfNeeded()
            }
        })
    }
    
    func configCell(_ topline : String, bottomLine : NSMutableAttributedString, showSwitcher : Bool, status : Bool, complete : switchActionBlock?) {
        topLineLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        topLineLabel.adjustsFontForContentSizeCategory = true
        bottomTextView.font = UIFont.preferredFont(forTextStyle: .footnote)
        bottomTextView.adjustsFontForContentSizeCategory = true
        
        topLineLabel.text = topline
        bottomTextView.attributedText = bottomLine
        
        switchView.isOn = status
        callback = complete
        
        self.accessibilityLabel = topline
        self.accessibilityElements = [switchView as Any]
        self.switchView.accessibilityLabel = (topLineLabel.text ?? "") + (bottomTextView.text ?? "")
        
        switchView.isHidden = !showSwitcher
        
        self.layoutIfNeeded()
    }
    
    
    
    @available(iOS, deprecated: 10.0)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        if (url.scheme?.contains("mailto"))! && characterRange.location > 55{
            self.delegate?.mailto()
        }
        return false
    }
    
    //For iOS 10
    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if (url.scheme?.contains("mailto"))! && characterRange.location > 55{
            self.delegate?.mailto()
        }
        return false
    }
}

extension SwitchTwolineCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
