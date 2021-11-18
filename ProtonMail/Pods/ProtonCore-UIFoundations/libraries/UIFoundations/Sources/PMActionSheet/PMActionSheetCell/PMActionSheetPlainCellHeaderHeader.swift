//
//  PMActionSheetPlainCellHeaderHeader.swift
//  ProtonCore-UIFoundations - Created on 20/08/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

class PMActionSheetPlainCellHeader: UITableViewHeaderFooterView, LineSeparatable, Reusable {
    private lazy var label = UILabel(nil, font: .systemFont(ofSize: 13),
                                     textColor: ColorProvider.TextWeak)
    private var separator: UIView?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        setupBackground()
        setupLabel()
    }

    func setupBackground() {
        contentView.backgroundColor = ColorProvider.BackgroundNorm
    }
    func setupLabel() {
        addSubview(label)
        label.centerXInSuperview(constant: 16)
        label.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 23).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
        label.numberOfLines = 1
        label.backgroundColor = ColorProvider.BackgroundNorm
        separator = addSeparator(padding: 0)
    }

    func config(title: String) {
        label.text = title.uppercased()
    }
}
