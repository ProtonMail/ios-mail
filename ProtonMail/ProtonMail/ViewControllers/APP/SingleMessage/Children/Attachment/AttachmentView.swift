//
//  AttachmentView.swift
//  Proton Mail
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

import ProtonCoreUIFoundations
import UIKit

class AttachmentView: UIView {
    private let topSeparator = SubViewsFactory.separator
    let iconView = SubViewsFactory.iconView
    let titleLabel = UILabel.init(frame: .zero)
    let arrowIconView = SubViewsFactory.arrowIcon

    init() {
        super.init(frame: .zero)
        addSubViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubViews() {
        addSubview(topSeparator)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(arrowIconView)
    }

    private func setupLayout() {
        [
            self.heightAnchor.constraint(equalToConstant: 48).setPriority(as: .oneLessThanRequired)
        ].activate()

        [
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 1)
        ].activate()

        [
            iconView.heightAnchor.constraint(equalToConstant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ].activate()

        [
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: arrowIconView.leadingAnchor, constant: -8)
        ].activate()

        [
            arrowIconView.heightAnchor.constraint(equalToConstant: 20),
            arrowIconView.widthAnchor.constraint(equalToConstant: 20),
            arrowIconView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            arrowIconView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ].activate()
    }
}

private enum SubViewsFactory {

    static var iconView: UIImageView {
        let view = UIImageView(image: IconProvider.paperClip.withRenderingMode(.alwaysTemplate))
        view.contentMode = .scaleAspectFit
        view.tintColor = ColorProvider.IconWeak
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
