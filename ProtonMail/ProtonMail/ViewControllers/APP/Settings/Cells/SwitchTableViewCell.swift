//
//  SwitchTableViewCell.swift
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

import ProtonCore_UIFoundations
import UIKit

final class SwitchTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }

    typealias ActionStatus = (_ isOK: Bool) -> Void
    typealias SwitchActionBlock = (_ newStatus: Bool, _ feedback: @escaping ActionStatus) -> Void

    override func awakeFromNib() {
        super.awakeFromNib()
        switchView.onTintColor = ColorProvider.BrandNorm
        switchView.tintColor = ColorProvider.Shade60
        switchView.layer.cornerRadius = 16
        switchView.clipsToBounds = true
        switchView.backgroundColor = ColorProvider.Shade60
        selectionStyle = .none
    }

    private var onSwitch: SwitchActionBlock?

    @IBOutlet private weak var centerConstraint: NSLayoutConstraint!
    // swiftlint:disable private_outlet
    @IBOutlet weak var topLineLabel: UILabel!
    @IBOutlet weak var switchView: UISwitch!

    override func prepareForReuse() {
        super.prepareForReuse()

        self.switchView.isEnabled = true
        self.switchView.onTintColor = ColorProvider.BrandNorm
    }

    @IBAction func switchAction(_ sender: UISwitch) {
        let status = sender.isOn
        onSwitch?(status) { isOK -> Void in
            if isOK == false {
                self.switchView.setOn(false, animated: true)
                self.layoutIfNeeded()
            }
        }
    }

    func configCell(_ topline: String, isOn: Bool, onSwitch: @escaping SwitchActionBlock) {
        let leftAttributes = FontManager.Default.alignment(.left)
        topLineLabel.attributedText = NSMutableAttributedString(string: topline, attributes: leftAttributes)
        switchView.isOn = isOn
        self.onSwitch = onSwitch
        self.accessibilityLabel = topline
        self.accessibilityElements = [switchView as Any]
        self.switchView.accessibilityLabel = topline
        centerConstraint.priority = UILayoutPriority(rawValue: 750.0)
        self.switchView.accessibilityLabel = topline
        self.layoutIfNeeded()
    }
}
