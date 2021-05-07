//
//  PMActionSheetPlainCell.swift
//  ProtonMail - Created on 23.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

final class PMActionSheetPlainCell: UITableViewCell {

    private var separator: UIView?
    @IBOutlet private var leftIcon: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var leftIconLeftConstraint: NSLayoutConstraint!
    @IBOutlet private var titleLeftToIcon: NSLayoutConstraint!
    @IBOutlet private var titleLeftToSuperView: NSLayoutConstraint!

    class func nib() -> UINib {
        return UINib(nibName: "PMActionSheetPlainCell", bundle: PMUIFoundations.bundle)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.separator = self.addSeparator(leftRef: self.leftIcon, constant: -16)
    }

    func config(item: PMActionSheetPlainItem) {

        if let icon = item.icon {
            self.leftIcon.image = icon
            self.leftIcon.tintColor = item.iconColor
            self.setupTitleLeftConstraint(hasLeftIcon: true)
        } else {
            self.leftIcon.image = nil
            self.setupTitleLeftConstraint(hasLeftIcon: false)
        }

        self.titleLabel.text = item.title
        self.titleLabel.textColor = item.textColor
        self.titleLabel.textAlignment = item.alignment
        self.separator?.isHidden = !item.hasSeparator
        self.accessoryType = item.isOn ? .checkmark: .none
        self.accessibilityIdentifier = item.title
        self.setupIndentation(level: item.indentationLevel,
                              width: item.indentationWidth)
    }

    private func setupTitleLeftConstraint(hasLeftIcon: Bool) {
        if hasLeftIcon {
            self.titleLeftToIcon.isActive = true
            self.titleLeftToSuperView.isActive = false
        } else {
            self.titleLeftToIcon.isActive = false
            self.titleLeftToSuperView.isActive = true
        }
    }

    private func setupIndentation(level: Int, width: CGFloat) {
        if titleLeftToIcon.isActive {
            // this item has left icon
            self.leftIconLeftConstraint.constant = 16 + CGFloat(level) * width
        } else {
            // this item doesn't have left icon
            self.titleLeftToSuperView.constant = 16 + CGFloat(level) * width
        }
    }

}
