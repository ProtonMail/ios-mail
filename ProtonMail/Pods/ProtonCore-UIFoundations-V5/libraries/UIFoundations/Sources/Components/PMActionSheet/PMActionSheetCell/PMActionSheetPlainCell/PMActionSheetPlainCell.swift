//
//  PMActionSheetPlainCell.swift
//  ProtonCore-UIFoundations - Created on 23.07.20.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_Foundations

final class PMActionSheetPlainCell: UITableViewCell, AccessibleView {

    private var separator: UIView?
    @IBOutlet private var leftIcon: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    @IBOutlet private var leftIconLeftConstraint: NSLayoutConstraint!
    @IBOutlet private var titleLeftToIcon: NSLayoutConstraint!
    @IBOutlet private var titleLeftToSuperView: NSLayoutConstraint!
    @IBOutlet private var titleRightToDetail: NSLayoutConstraint!
    @IBOutlet private var titleRightToIcon: NSLayoutConstraint!
    @IBOutlet private var titleRightToSuperView: NSLayoutConstraint!
    @IBOutlet private var rightIcon: UIImageView!
    @IBOutlet private var rightIconWidth: NSLayoutConstraint!
    @IBOutlet private var rightIconHeight: NSLayoutConstraint!
    @IBOutlet private weak var titleRightIcon: UIImageView!
    @IBOutlet weak var titleRightIconWidth: NSLayoutConstraint!

    class func nib() -> UINib {
        return UINib(nibName: "PMActionSheetPlainCell", bundle: PMUIFoundations.bundle)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.separator = self.addSeparator(leftRef: self.leftIcon, constant: -16)
        titleLabel.font = .adjustedFont(forTextStyle: .subheadline)
        detailLabel.font = .adjustedFont(forTextStyle: .subheadline)
    }

    func config(item: PMActionSheetPlainItem, indexPath: IndexPath) {
        self.backgroundColor = ColorProvider.BackgroundNorm
        let hasLeftIcon: Bool
        if let leftIcon = item.icon {
            self.leftIcon.image = leftIcon
            self.leftIcon.tintColor = item.iconColor
            hasLeftIcon = true
        } else {
            self.leftIcon.image = nil
            hasLeftIcon = false
        }

        let hasRightIcon: Bool
        if let rightIcon = item.rightIcon {
            self.rightIcon.image = rightIcon
            self.rightIcon.tintColor = item.rightIconColor
            self.rightIconWidth.constant = 20
            self.rightIconHeight.constant = 20
            hasRightIcon = true
        } else if let rightIcon = item.markType.icon {
            self.rightIcon.image = rightIcon
            self.rightIcon.tintColor = ColorProvider.BrandNorm
            hasRightIcon = true
        } else {
            self.rightIcon.image = nil
            hasRightIcon = false
        }

        if let titleRightIcon = item.titleRightIcon {
            self.titleRightIcon.image = titleRightIcon
        } else {
            titleRightIconWidth.constant = 0
        }

        detailLabel.setContentCompressionResistancePriority(
            item.detailCompressionResistancePriority,
            for: .horizontal
        )
        detailLabel.text = item.detail
        detailLabel.textColor = item.detailColor
        detailLabel.textAlignment = .right

        self.titleLabel.text = item.title
        self.titleLabel.textColor = item.textColor
        self.titleLabel.textAlignment = item.alignment
        self.separator?.isHidden = !item.hasSeparator
        self.accessibilityIdentifier = "itemIndex_\(indexPath.section).\(indexPath.row)"
        self.accessibilityLabel = item.title
        self.setupTitleConstraints(
            level: item.indentationLevel,
            width: item.indentationWidth,
            alignment: item.alignment,
            hasLeftIcon: hasLeftIcon,
            hasRightIcon: hasRightIcon,
            hasDetail: item.detail != nil
        )
        generateAccessibilityIdentifiers()
    }

    private func setupTitleConstraints(
        level: Int,
        width: CGFloat,
        alignment: NSTextAlignment,
        hasLeftIcon: Bool,
        hasRightIcon: Bool,
        hasDetail: Bool
    ) {

        self.titleLeftToIcon.isActive = hasLeftIcon
        self.titleLeftToSuperView.isActive = !hasLeftIcon

        switch (hasRightIcon, hasDetail) {
        case (false, false):
            titleRightToSuperView.isActive = true
            titleRightToIcon.isActive = false
            titleRightToDetail.isActive = false
        case (false, true):
            titleRightToSuperView.isActive = false
            titleRightToIcon.isActive = false
            titleRightToDetail.isActive = true
        case (true, false):
            titleRightToSuperView.isActive = false
            titleRightToIcon.isActive = true
            titleRightToDetail.isActive = false
        case (true, true):
            titleRightToSuperView.isActive = false
            titleRightToIcon.isActive = true
            titleRightToDetail.isActive = true
        }

        let indentationOffset = CGFloat(level) * width
        if hasLeftIcon {
            self.leftIconLeftConstraint.constant = 16 + indentationOffset
        } else {
            self.titleLeftToSuperView.constant = 16 + indentationOffset
        }
    }
}
