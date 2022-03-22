//
//  AttachmentView.swift
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

import ProtonCore_UIFoundations
import UIKit

class AttachmentView: UIView {
    let iconView = SubViewsFactory.iconView
    let titleLabel = UILabel.init(frame: .zero)
    let arrowIconView = SubViewsFactory.arrowIcon
    private let separator = SubViewsFactory.separator

    init() {
        super.init(frame: .zero)
        addSubViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubViews() {
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(arrowIconView)
        addSubview(separator)
    }

    private func setupLayout() {
        [
            self.heightAnchor.constraint(equalToConstant: 48)
        ].activate()

        [
            iconView.heightAnchor.constraint(equalToConstant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 14),
            iconView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -14)
        ].activate()

        [
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: arrowIconView.leadingAnchor, constant: -8)
        ].activate()

        [
            arrowIconView.heightAnchor.constraint(equalToConstant: 20),
            arrowIconView.widthAnchor.constraint(equalToConstant: 20),
            arrowIconView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            arrowIconView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ].activate()

        [
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
    }
}

private enum SubViewsFactory {

    static var iconView: UIImageView {
        let view = UIImageView(image: IconProvider.paperClip.withRenderingMode(.alwaysTemplate))
        view.contentMode = .scaleAspectFit
        view.tintColor = ColorProvider.TextNorm
        return view
    }

    static var arrowIcon: UIImageView {
        let view = UIImageView(image: IconProvider.chevronRight.withRenderingMode(.alwaysTemplate))
        view.contentMode = .scaleAspectFit
        view.tintColor = ColorProvider.IconWeak
        return view
    }

    static var separator: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.Shade20
        return view
    }

}
