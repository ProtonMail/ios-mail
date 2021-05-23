//
//  PMActionSheetPlainCellHeaderHeader.swift
//  PMUIFoundations - Created on 20/08/2020.
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

class PMActionSheetPlainCellHeader: UITableViewHeaderFooterView, LineSeparatable, Reusable {
    private lazy var label = UILabel(nil, font: .systemFont(ofSize: 13),
                                     textColor: AdaptiveTextColors._N3)
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
        contentView.backgroundColor = BackgroundColors._Main
    }
    func setupLabel() {
        addSubview(label)
        label.centerXInSuperview(constant: 16)
        label.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 23).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
        label.numberOfLines = 1
        label.backgroundColor = BackgroundColors._Main
        separator = addSeparator(padding: 0)
    }

    func config(title: String) {
        label.text = title.uppercased()
    }
}
