//
//  SwitchTwolineCell.swift
//  Proton Mail - Created on 3/17/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import MessageUI
import ProtonCore_UIFoundations

protocol SwitchTwolineCellDelegate {
    func mailto()
}

@IBDesignable class SwitchTwolineCell: UITableViewCell, UITextViewDelegate {
    typealias ActionStatus = (_ isOK: Bool) -> Void
    typealias switchActionBlock = (_ cell: SwitchTwolineCell?, _ newStatus: Bool, _ feedback: @escaping ActionStatus) -> Void

    var callback: switchActionBlock?
    var delegate: SwitchTwolineCellDelegate?

    @IBOutlet weak var topLineBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var topLineLabel: UILabel!

    @IBOutlet weak var bottomTextView: UITextView!
    @IBOutlet weak var switchView: UISwitch!

    static var CellID: String {
        return "\(self)"
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        topLineLabel.font = UIFont.preferredFont(for: .footnote, weight: .regular)
        topLineLabel.adjustsFontForContentSizeCategory = true

        bottomTextView.font = UIFont.preferredFont(for: .caption1, weight: .regular)
        bottomTextView.adjustsFontForContentSizeCategory = true

        bottomTextView.isSelectable = true
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

    func configCell(_ topline: String, bottomLine: NSMutableAttributedString, showSwitcher: Bool, status: Bool, complete: switchActionBlock?) {
        topLineLabel.font = UIFont.preferredFont(for: .subheadline, weight: .regular)
        topLineLabel.adjustsFontForContentSizeCategory = true
        topLineLabel.textColor = ColorProvider.TextNorm
        bottomTextView.font = UIFont.preferredFont(for: .footnote, weight: .regular)
        bottomTextView.adjustsFontForContentSizeCategory = true
        bottomTextView.textColor = ColorProvider.TextWeak

        topLineLabel.text = topline
        bottomTextView.attributedText = bottomLine

        switchView.isOn = status
        switchView.tintColor = ColorProvider.BrandNorm
        callback = complete

        self.accessibilityLabel = topline
        self.accessibilityElements = [switchView as Any]
        self.switchView.accessibilityLabel = (topLineLabel.text ?? "") + (bottomTextView.text ?? "")

        switchView.isHidden = !showSwitcher

        self.layoutIfNeeded()
    }

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if (url.scheme?.contains("mailto"))! && characterRange.location > 55 {
            self.delegate?.mailto()
        }
        return false
    }
}
