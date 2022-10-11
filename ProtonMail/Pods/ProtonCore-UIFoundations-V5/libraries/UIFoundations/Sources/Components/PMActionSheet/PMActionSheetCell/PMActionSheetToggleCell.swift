//
//  PMActionSheetToggleCell.swift
//  ProtonCore-UIFoundations - Created on 21.07.20.
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

protocol PMActionSheetToggleDelegate: AnyObject {
    func toggleTriggeredAt(indexPath: IndexPath)
}

final class PMActionSheetToggleCell: UITableViewCell, AccessibleView {
    // MARK: Constants
    private let PADDING: CGFloat = 16

    private let toggle: UISwitch
    private weak var delegate: PMActionSheetToggleDelegate?
    private var indexPath: IndexPath = IndexPath(row: -1, section: -1)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.toggle = UISwitch()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        self.setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel?.font = .adjustedFont(forTextStyle: .subheadline)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Public function
extension PMActionSheetToggleCell {
    func config(item: PMActionSheetToggleItem, at indexPath: IndexPath, delegate: PMActionSheetToggleDelegate) {
        self.backgroundColor = ColorProvider.BackgroundNorm
        self.imageView?.image = item.icon
        self.imageView?.tintColor = item.iconColor
        self.textLabel?.font = .adjustedFont(forTextStyle: .subheadline)
        self.textLabel?.text = item.title
        self.textLabel?.textColor = item.textColor
        self.toggle.isOn = item.isOn
        self.toggle.onTintColor = item.toggleColor
        self.accessibilityIdentifier = "itemIndex_\(indexPath.section).\(indexPath.row)"
        self.accessibilityLabel = item.title
        self.indexPath = indexPath
        self.delegate = delegate
        generateAccessibilityIdentifiers()
    }
}

// MARK: Private function
extension PMActionSheetToggleCell {
    private func setup() {
        self.setupToggle()
        self.addSeparator(leftRef: self.textLabel!, constant: -16)
    }

    private func setupToggle() {
        self.toggle.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.toggle)
        self.toggle.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -1 * PADDING).isActive = true
        self.toggle.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.toggle.addTarget(self, action: #selector(self.triggerToggle), for: .valueChanged)
    }

    @objc private func triggerToggle() {
        self.delegate?.toggleTriggeredAt(indexPath: self.indexPath)
    }
}
