//
//  HeaderContainerView.swift
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

import ProtonCore_UIFoundations

class HeaderContainerView: UIView {

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    let expandArrowControl = UIControl(frame: .zero)
    let contentContainer = UIView(frame: .zero)
    let expandArrowImageView = SubviewsFactory.expandArrowImageView

    private func addSubviews() {
        addSubview(contentContainer)
        addSubview(expandArrowControl)

        expandArrowControl.addSubview(expandArrowImageView)
    }

    private func setUpLayout() {
        [
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()

        [contentContainer.widthAnchor.constraint(equalTo: widthAnchor)].activate()

        [
            expandArrowControl.topAnchor.constraint(equalTo: topAnchor),
            expandArrowControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            expandArrowControl.widthAnchor.constraint(equalToConstant: 40),
            expandArrowControl.heightAnchor.constraint(equalToConstant: 90),
            expandArrowControl.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ].activate()

        [
            expandArrowImageView.topAnchor.constraint(equalTo: expandArrowControl.topAnchor, constant: 48),
            expandArrowImageView.trailingAnchor.constraint(equalTo: expandArrowControl.trailingAnchor, constant: -16)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var expandArrowImageView: UIImageView {
        let imageView = UIImageView()
        imageView.image = Asset.mailDownArrow.image
        imageView.tintColor = UIColorManager.IconWeak
        return imageView
    }

}
