//
//  SwitchTableViewCell.swift
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


import ProtonCore_UIFoundations
import UIKit

@IBDesignable class SwitchTableViewCell: UITableViewCell {
    static var CellID : String  {
        return "\(self)"
    }
    typealias ActionStatus = (_ isOK: Bool) -> Void
    typealias switchActionBlock = (_ cell: SwitchTableViewCell?, _ newStatus: Bool, _ feedback: @escaping ActionStatus) -> Void

    override func awakeFromNib() {
        super.awakeFromNib()
        switchView.onTintColor = UIColorManager.BrandNorm
        selectionStyle = .none
    }
    
    var callback : switchActionBlock?
    
    @IBOutlet weak var topLineBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var topLineLabel: UILabel!
    @IBOutlet weak var bottomLineLabel: UILabel!
    
    @IBOutlet weak var switchView: UISwitch!
    
    override func prepareForReuse() {
        self.switchView.isEnabled = true
        self.switchView.onTintColor = UIColorManager.BrandNorm
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
    
    func configCell(_ topline: String, bottomLine: String, status: Bool, complete: switchActionBlock?) {
        var leftAttributes = FontManager.Default
        leftAttributes.addTextAlignment(.left)
        topLineLabel.attributedText = NSMutableAttributedString(string: topline, attributes: leftAttributes)

        bottomLineLabel.text = bottomLine
        switchView.isOn = status
        callback = complete
        self.bottomLineLabel.isUserInteractionEnabled = false
        self.accessibilityLabel = topline
        self.accessibilityElements = [switchView as Any]
        self.switchView.accessibilityLabel = topline + bottomLine
        
        if bottomLine.isEmpty {
            //topLineBottomConstraint.priority = UILayoutPriority(1000.0)
            centerConstraint.priority = UILayoutPriority(rawValue: 750.0);
            bottomLineLabel.isHidden = true
            
        } else {
            topLineBottomConstraint.priority = UILayoutPriority(250.0)
            centerConstraint.priority = UILayoutPriority(rawValue: 1.0);
            bottomLineLabel.isHidden = false
        }
        self.layoutIfNeeded()
    }
}

extension SwitchTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
