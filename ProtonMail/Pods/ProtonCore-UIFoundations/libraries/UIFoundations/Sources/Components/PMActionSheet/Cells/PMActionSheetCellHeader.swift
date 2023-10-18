//
//  PMActionSheetPlainCellHeaderHeader.swift
//  ProtonCore-UIFoundations - Created on 20/08/2020.
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

#if os(iOS)

import UIKit
import ProtonCoreFoundations

final class PMActionSheetCellHeader: UITableViewHeaderFooterView, LineSeparatable, Reusable, AccessibleView {
    private lazy var label = UILabel(
        nil,
        font: .systemFont(ofSize: 13),
        textColor: PMActionSheetConfig.shared.sectionHeaderTextColor
    )
    private var separator: UIView?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    @available(iOS, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        setupBackground()
        setupLabel()
        generateAccessibilityIdentifiers()
    }

    func setupBackground() {
        contentView.backgroundColor = PMActionSheetConfig.shared.sectionHeaderBackground
    }

    func setupLabel() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
        label.numberOfLines = 1
        label.backgroundColor = .clear
        label.font = PMActionSheetConfig.shared.sectionHeaderFont
        label.adjustsFontForContentSizeCategory = true
    }

    func config(title: String, hasSeparator: Bool = false) {
        label.text = title
        if hasSeparator {
            separator = addSeparator(padding: 0)
        }
    }
}

#endif
