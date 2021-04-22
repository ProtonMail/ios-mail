//
//  MenuItemTableViewCell.swift
//  ProtonMail
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

protocol MenuItemTableViewCellDelegate: class {
    func clickCollapsedArrow(labelID: String)
}

class MenuItemTableViewCell: UITableViewCell, AccessibleCell {
    @IBOutlet private var icon: UIImageView!
    @IBOutlet private var name: UILabel!
    @IBOutlet private var badge: UILabel!
    @IBOutlet private var badgeBGView: UIView!
    @IBOutlet private var arrowBGView: UIView!
    @IBOutlet private var arrow: UIImageView!
    @IBOutlet private var arrowBGWdith: NSLayoutConstraint!
    @IBOutlet private var iconLeftConstraint: NSLayoutConstraint!
    private weak var delegate: MenuItemTableViewCellDelegate? = nil
    private var labelID: String = ""
    private var nameColor: String = "#FFFFFF"
    private var iconColor: String = "#FFFFFF"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView()
        selectedView.backgroundColor = .clear
        self.selectedBackgroundView = selectedView
        
        self.badgeBGView.setCornerRadius(radius: 10)
        self.arrow.image = UIImage(named: "mail_attachment-closed")
        self.arrow.highlightedImage = UIImage(named: "mail_attachment-open")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.clickArrow))
        self.arrowBGView.addGestureRecognizer(tap)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let textColor = highlighted ? UIColor(RRGGBB: UInt(0x9CA0AA)): UIColor(hexColorCode: self.nameColor)
        let iconColor = highlighted ? UIColor(RRGGBB: UInt(0x9CA0AA)): UIColor(hexColorCode: self.iconColor)
        
        self.name.textColor = textColor
        self.icon.tintColor = iconColor
    }
    
    /// - Parameters:
    ///   - label: Data of label
    ///   - showArrow: Show expand/collapse arrow?
    ///   - useFillIcon: Use fill icon for custom folder or not?
    ///   - delegate: delegate
    func config(by label: MenuLabel, showArrow: Bool = true, useFillIcon: Bool = false, delegate: MenuItemTableViewCellDelegate?) {
        self.nameColor = label.textColor
        self.name.textColor = UIColor(hexColorCode: self.nameColor)
        self.iconColor = label.iconColor
        self.icon.tintColor = UIColor(hexColorCode: self.iconColor)
        
        self.labelID = label.location.labelID
        self.delegate = delegate
        self.setupIcon(label: label, useFillIcon: useFillIcon)
        let num = label.expanded ? label.unread: label.aggreateUnread
        self.setup(badge: num)
        self.setupArrow(label: label, showArrow: showArrow)
        self.name.text = label.name
        self.setupIndentation(level: label.indentationLevel)
        self.setBackgroundColor(isSelected: label.isSelected)
        generateCellAccessibilityIdentifiers(label.name)
    }
    
    func update(textColor: UIColor) {
        let hex = textColor.toHex()
        self.nameColor = hex
        self.name.textColor = textColor
    }
    
    func update(iconColor: UIColor, alpha: CGFloat = 1) {
        let hex = iconColor.toHex()
        self.iconColor = hex
        self.icon.tintColor = iconColor
        self.icon.alpha = alpha
    }
    
    func update(attribure: [NSAttributedString.Key: Any]) {
        self.name.attributedText = self.name.text?.apply(style: attribure)
    }
}

// MARK: Private functions
extension MenuItemTableViewCell {
    private func setupIcon(label: MenuLabel, useFillIcon: Bool) {
        let location = label.location
        if let icon = location.icon {
            self.icon.image = icon
            return
        }
        guard case .customize(_) = location else {
            self.icon.image = nil
            return
        }
        
        if label.type == .folder {
            if label.subLabels.count > 0 {
                let icon = useFillIcon ? Asset.icFolderMultipleFilled.image: Asset.menuFolderMultiple.image
                self.icon.image = icon
            } else {
                let icon = useFillIcon ? Asset.icFolderFilled.image: Asset.menuFolder.image
                self.icon.image = icon
            }
        } else if label.type == .label {
            self.icon.image = Asset.mailUnreadIcon.image
        } else {
            self.icon.image = nil
        }
    }
    
    private func setup(badge: Int) {
        guard badge > 0 else {
            self.badgeBGView.isHidden = true
            self.badge.isHidden = true
            return
        }
        self.badgeBGView.isHidden = false
        self.badge.isHidden = false
        // Insert space between word so that corner radius looks better
        if badge > 9999 {
            self.badge.text = "9999+"
        } else {
            self.badge.text = "\(badge)"
        }
    }
    
    private func setupArrow(label: MenuLabel, showArrow: Bool) {
        
        guard showArrow else {
            self.arrowBGWdith.constant = 12
            self.arrow.isHidden = true
            return
        }
        
        switch label.location {
        case .customize(_):
            guard label.type == .folder else {
                self.arrowBGWdith.constant = 12
                self.arrow.isHidden = true
                return
            }
            
            self.arrowBGWdith.constant = 38
            self.arrow.isHidden = label.subLabels.count == 0
            self.arrow.isHighlighted = label.expanded
            
        default:
            self.arrowBGWdith.constant = 12
            self.arrow.isHidden = true
        }
    }
    
    private func setupIndentation(level: Int) {
        let base: CGFloat = 17.5
        self.iconLeftConstraint.constant = base + 20.0 * CGFloat(level)
    }
    
    private func setBackgroundColor(isSelected: Bool) {
        let color: UIColor = isSelected ? UIColor(RRGGBB: UInt(0x3C4B88)): .clear
        self.contentView.backgroundColor = color
    }
    
    @objc private func clickArrow() {
        self.delegate?.clickCollapsedArrow(labelID: self.labelID)
    }
}
