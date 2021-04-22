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

import PMUIFoundations
import UIKit

class NewMessageBodyView: UIView {
    let reloadContainerView = UIView(frame: .zero)
    let reloadButton: ProtonButton = SubViewsFactory.reloadButton
    let alertIconBackgroundView: UIView = SubViewsFactory.alertIconBackgroundView
    let alertIconView: UIView = SubViewsFactory.alertIconView
    let alertTextLabel: UILabel = SubViewsFactory.alertTextLabel

    init() {
        super.init(frame: .zero)
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

    func addReloadView() {
        subviews.forEach({ $0.removeFromSuperview() })
        reloadContainerView.backgroundColor = UIColorManager.BackgroundNorm
        addSubview(reloadContainerView)
        reloadContainerView.addSubview(reloadButton)
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
            alertTextLabel.trailingAnchor.constraint(equalTo: reloadContainerView.trailingAnchor, constant: -52)
        ].activate()

        alertTextLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        [
            reloadButton.topAnchor.constraint(equalTo: alertTextLabel.bottomAnchor, constant: 28),
            reloadButton.heightAnchor.constraint(equalToConstant: 48),
            reloadButton.widthAnchor.constraint(equalToConstant: 125),
            reloadButton.bottomAnchor.constraint(equalTo: reloadContainerView.bottomAnchor),
            reloadButton.centerXAnchor.constraint(equalTo: reloadContainerView.centerXAnchor)
        ].activate()
    }
}

private enum SubViewsFactory {
    static var alertIconBackgroundView: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColorManager.BackgroundSecondary
        view.setCornerRadius(radius: 9)
        return view
    }

    static var alertIconView: UIImageView {
        let imageView = UIImageView(image: Asset.mailAlertIcon.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColorManager.IconHint
        return imageView
    }

    static var alertTextLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }

    static var reloadButton: ProtonButton {
        let button = ProtonButton(frame: .zero)
        button.setMode(mode: .solid)
        button.tintColor = UIColorManager.InteractionNorm
        return button
    }
}
