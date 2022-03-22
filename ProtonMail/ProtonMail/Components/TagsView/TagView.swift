//
//  TagView.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton AG
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

import UIKit

class TagView: UIView {

    let tagLabel = UILabel()

    init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        addSubviews()
        setUpLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setCornerRadius(radius: frame.height / 2)
    }

    private func addSubviews() {
        tagLabel.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(tagLabel)
    }

    private func setUpLayout() {
        [
            tagLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            tagLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            tagLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            tagLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
