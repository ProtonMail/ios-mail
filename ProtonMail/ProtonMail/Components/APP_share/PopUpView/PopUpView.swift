// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_UIFoundations
import UIKit

class PopUpView: UIView {
    private var superView: UIView = SubviewsFactory.superView
    private var titleLabel: UILabel = SubviewsFactory.titleLabel
    private var descriptionLabel: UILabel = SubviewsFactory.descriptionLabel
    private var button: UIButton = SubviewsFactory.button
    private var imageView: UIImageView = SubviewsFactory.imageView
    private var backgroundView: UIView = SubviewsFactory.backgroundView
    private var topBGView: UIView = SubviewsFactory.topBGView
    private var dismissImageView: UIImageView = SubviewsFactory.dismissImageView

    typealias ButtonActionBlock = () -> Void
    typealias DismissActionBlock = () -> Void

    var callback: ButtonActionBlock?
    var dismissAction: DismissActionBlock?

    @objc
    func dismiss(_ sender: UITapGestureRecognizer) {
        self.remove()
        self.dismissAction?()
    }

    @objc
    func buttonPressed(_ sender: UIButton) {
        callback?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubViews()
        self.setupLayout()
    }

    init(title: String,
         description: String,
         image: UIImage?,
         titleOfButton: String?,
         buttonAction: ButtonActionBlock?,
         dismissAction: DismissActionBlock? = nil) {
        super.init(frame: CGRect.zero)

        self.titleLabel.text = title
        self.descriptionLabel.text = description
        self.imageView.image = image
        self.callback = buttonAction
        self.button.setTitle(titleOfButton, for: .normal)
        self.dismissAction = dismissAction

        self.addSubViews()
        self.setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addSubViews()
        self.setupLayout()
    }

    private func addSubViews() {
        self.addSubview(self.topBGView)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PopUpView.dismiss(_:)))
        self.dismissImageView.addGestureRecognizer(tapRecognizer)
        self.addSubview(self.dismissImageView)
        self.addSubview(self.imageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
        self.addSubview(self.button)
    }

    private func setupLayout() {
        // set bg color of view
        self.backgroundColor = ColorProvider.BackgroundNorm

        [
            self.topBGView.topAnchor.constraint(equalTo: self.topAnchor),
            self.topBGView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.topBGView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.topBGView.heightAnchor.constraint(equalToConstant: 160)
        ].activate()

        [
            self.dismissImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 24),
            self.dismissImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.dismissImageView.widthAnchor.constraint(equalToConstant: 24),
            self.dismissImageView.heightAnchor.constraint(equalToConstant: 24)
        ].activate()

        [
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 18),
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 118.64),
            self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -77.42)
        ].activate()

        [
            self.titleLabel.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 42),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ].activate()

        [
            self.descriptionLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 8),
            self.descriptionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.descriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ].activate()

        [
            self.button.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 16),
            self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            self.button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
            self.button.heightAnchor.constraint(equalToConstant: 48)
        ].activate()
    }
}

extension PopUpView {
    func popUp(on baseView: UIView) {
        self.superView = baseView

        // sizing
        let popUpWidth: CGFloat = baseView.bounds.width
        let popUpHeight: CGFloat = 276.0

        let size: CGSize = CGSize(width: popUpWidth, height: popUpHeight)
        self.frame = CGRect(origin: .zero, size: size)
    }

    func remove() {
        self.removeFromSuperview()
    }
}

private enum SubviewsFactory {
    static var superView: UIView {
        let view = UIView(frame: .zero)
        return view
    }

    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textColor = ColorProvider.TextNorm
        return label
    }

    static var descriptionLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = ColorProvider.TextWeak
        label.numberOfLines = 3
        return label
    }

    static var button: UIButton {
        let button = UIButton(frame: .zero)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.titleLabel?.numberOfLines = 1
        button.setTitleColor(ColorProvider.BackgroundNorm, for: .normal)
        button.tintColor = ColorProvider.BrandNorm
        button.backgroundColor = ColorProvider.BrandNorm
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(PopUpView.buttonPressed(_:)), for: .touchUpInside)
        return button
    }

    static var imageView: UIImageView {
        let view = UIImageView(image: Asset.esIcon.image)
        return view
    }

    static var backgroundView: UIView {
        let view = UIView(frame: .zero)
        return view
    }

    static var topBGView: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundSecondary
        return view
    }

    static var dismissImageView: UIImageView {
        let view = UIImageView(image: Asset.mailLabelCrossIcon.image)
        view.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        view.tintColor = ColorProvider.IconNorm
        view.isUserInteractionEnabled = true
        return view
    }
}
