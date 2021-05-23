//
//  TagView.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

class TagView: UIView {

    let imageView = UIImageView()
    let tagLabel = UILabel()
    let stackView = UIStackView()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setCornerRadius(radius: frame.height / 2)
    }

    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(tagLabel)

        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        tagLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setUpLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ].forEach {
            $0.priority = .defaultLow
            $0.isActive = true
        }
    }

    private func setUpViews() {
        stackView.spacing = 4
        imageView.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        nil
    }

}
