//
//  MenuItemTableViewCell.swift
//  Proton Mail
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

import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol MenuItemTableViewCellDelegate: AnyObject {
    func clickCollapsedArrow(labelID: LabelID)
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
    private weak var delegate: MenuItemTableViewCellDelegate?
    private var labelID: LabelID = ""
    private var originalTextColor: UIColor = .clear
    private var isUsedInSideBar = false
    private var originalBackgroundColor: UIColor = .clear

    override func awakeFromNib() {
        super.awakeFromNib()

        self.contentView.backgroundColor = ColorProvider.BackgroundNorm

        self.badgeBGView.setCornerRadius(radius: 10)
        self.arrow.image = IconProvider.chevronDown
        self.arrow.highlightedImage = IconProvider.chevronUp
        self.arrow.tintColor = ColorProvider.IconNorm

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.clickArrow))
        self.arrowBGView.addGestureRecognizer(tap)

        arrowBGView.isAccessibilityElement = true
        arrowBGView.accessibilityLabel = arrow.isHighlighted ? LocalString._menu_collapse_folder : LocalString._menu_expand_folder
        arrowBGView.accessibilityTraits = .button
        accessibilityElements = [name as Any, arrowBGView as Any]
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let textColor = highlighted ? ColorProvider.TextDisabled : originalTextColor
        name.textColor = textColor
        if isUsedInSideBar {
            let bgColor = highlighted ? ColorProvider.SidebarInteractionWeakPressed : originalBackgroundColor
            self.contentView.backgroundColor = bgColor
        }
        arrowBGView.accessibilityLabel = arrow.isHighlighted ? LocalString._menu_collapse_folder : LocalString._menu_expand_folder
    }

    /// - Parameters:
    ///   - label: Data of label
    ///   - showArrow: Show expand/collapse arrow?
    ///   - useFillIcon: Use fill icon for custom folder or not?
    ///   - delegate: delegate
    func config(by label: MenuLabel, showArrow: Bool = true, useFillIcon: Bool = false, isUsedInSideBar: Bool = false, delegate: MenuItemTableViewCellDelegate?) {
        self.isUsedInSideBar = isUsedInSideBar
        self.labelID = label.location.labelID
        self.delegate = delegate
        self.setupIcon(label: label, useFillIcon: useFillIcon, isSelected: label.isSelected)
        let num = label.expanded ? label.unread: label.aggreateUnread
        self.setup(badge: num)
        self.setupArrow(label: label, showArrow: showArrow)
        self.setupArrowColor()
        self.name.text = label.name
        self.setNameColor(label: label, isSelected: label.isSelected)
        self.setupIndentation(level: label.indentationLevel)
        self.setBackgroundColor(isSelected: label.isSelected)
        generateCellAccessibilityIdentifiers(label.name)
    }

    func update(textColor: UIColor) {
        self.name.textColor = textColor
        originalTextColor = textColor
    }

    func update(iconColor: UIColor, alpha: CGFloat = 1) {
        self.icon.tintColor = iconColor
        self.icon.alpha = alpha
    }

    func update(attribure: [NSAttributedString.Key: Any]) {
        self.name.attributedText = self.name.text?.apply(style: attribure)
    }

    func update(badge: Int) {
        self.setup(badge: badge)
    }
}

// MARK: Private functions
extension MenuItemTableViewCell {
    private func setupIcon(label: MenuLabel, useFillIcon: Bool, isSelected: Bool) {
        let location = label.location
        if let icon = location.icon {
            self.icon.image = icon
            return
        }
        guard case .customize = location else {
            self.icon.image = nil
            return
        }

        if label.type == .folder {
            if label.subLabels.count > 0 {
                let icon = useFillIcon ? IconProvider.foldersFilled: IconProvider.folders
                self.icon.image = icon
            } else {
                let icon = useFillIcon ? IconProvider.folderFilled: IconProvider.folder
                self.icon.image = icon
            }
        } else if label.type == .label {
            self.icon.image = IconProvider.circleFilled
        } else {
            self.icon.image = nil
        }
    }

    private func setup(badge: Int) {
        guard badge > 0 else {
            self.badge.text = ""
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
        defer {
            self.arrowBGView.isAccessibilityElement = !arrow.isHidden
        }
        guard showArrow else {
            self.arrowBGWdith.constant = 12
            self.arrow.isHidden = true
            return
        }

        switch label.location {
        case .customize:
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

    private func setupArrowColor() {
        self.arrow.tintColor = ColorProvider.SidebarIconNorm
    }

    private func setupIndentation(level: Int) {
        let base: CGFloat = 17.5
        self.iconLeftConstraint.constant = base + 20.0 * CGFloat(level)
    }

    private func setBackgroundColor(isSelected: Bool) {
        let color: UIColor = isSelected ? ColorProvider.SidebarInteractionPressed : .clear
        self.contentView.backgroundColor = color
        originalBackgroundColor = color
    }

    private func setNameColor(label: MenuLabel, isSelected: Bool) {
        if isSelected {
            self.name.textColor = ColorProvider.SidebarTextNorm
        } else if let nameColor = label.textColor {
            self.name.textColor = UIColor(hexColorCode: nameColor)
        } else {
            self.name.textColor = ColorProvider.SidebarTextNorm
        }
        originalTextColor = self.name.textColor
    }

    @objc
    private func clickArrow() {
        self.delegate?.clickCollapsedArrow(labelID: self.labelID)
    }
}
