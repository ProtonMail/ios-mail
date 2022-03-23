//
//  NewMessageBodyView.swift
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
import UIKit

class NewMessageBodyView: UIView {
    let reloadContainerView = UIView(frame: .zero)
    let alertIconBackgroundView: UIView = SubViewsFactory.alertIconBackgroundView
    let alertIconView: UIView = SubViewsFactory.alertIconView
    let alertTextLabel: UILabel = SubViewsFactory.alertTextLabel

    init() {
        super.init(frame: .zero)
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        nil
    }

    func embed(_ view: UIView) {
        subviews.forEach({ $0.removeFromSuperview() })
        addSubview(view)
        [
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ].activate()
    }

    func removeReloadView() {
        reloadContainerView.removeFromSuperview()
    }

    func addReloadView() {
        subviews.forEach({ $0.removeFromSuperview() })
        reloadContainerView.backgroundColor = ColorProvider.BackgroundNorm
        addSubview(reloadContainerView)
        reloadContainerView.addSubview(alertIconBackgroundView)
        reloadContainerView.addSubview(alertIconView)
        reloadContainerView.addSubview(alertTextLabel)

        setupLayout()
    }

    private func setupLayout() {
        [
            reloadContainerView.topAnchor.constraint(equalTo: self.topAnchor),
            reloadContainerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            reloadContainerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            reloadContainerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ].activate()

        [
            alertIconBackgroundView.heightAnchor.constraint(equalToConstant: 80.0),
            alertIconBackgroundView.widthAnchor.constraint(equalToConstant: 80.0),
            alertIconBackgroundView.centerXAnchor.constraint(equalTo: reloadContainerView.centerXAnchor),
            alertIconBackgroundView.topAnchor.constraint(equalTo: reloadContainerView.topAnchor, constant: 100)
        ].activate()

        [
            alertIconView.heightAnchor.constraint(equalToConstant: 32.0),
            alertIconView.widthAnchor.constraint(equalToConstant: 32.0),
            alertIconView.centerXAnchor.constraint(equalTo: alertIconBackgroundView.centerXAnchor),
            alertIconView.centerYAnchor.constraint(equalTo: alertIconBackgroundView.centerYAnchor)
        ].activate()

        [
            alertTextLabel.topAnchor.constraint(equalTo: alertIconBackgroundView.bottomAnchor, constant: 20),
            alertTextLabel.leadingAnchor.constraint(equalTo: reloadContainerView.leadingAnchor, constant: 52),
            alertTextLabel.trailingAnchor.constraint(equalTo: reloadContainerView.trailingAnchor, constant: -52),
            alertTextLabel.bottomAnchor.constraint(equalTo: reloadContainerView.bottomAnchor)
        ].activate()

        alertTextLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}

private enum SubViewsFactory {
    static var alertIconBackgroundView: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.setCornerRadius(radius: 9)
        return view
    }

    static var alertIconView: UIImageView {
        let imageView = UIImageView(image: Asset.mailAlertIcon.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconHint
        return imageView
    }

    static var alertTextLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }
}
