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
    private weak var superView: UIView!
    private var titleLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var button: UIButton!
    private var imageView: UIImageView!
    private var backgroundView: UIView!
    private var topBGView: UIView!

    typealias ButtonActionBlock = () -> Void
    typealias DismissActionBlock = () -> Void

    var callback: ButtonActionBlock?
    var dismissAction: DismissActionBlock?

    @objc func dismiss(_ sender: UITapGestureRecognizer) {
        self.remove()
        self.dismissAction?()
    }

    func buttonPressed(_ sender: UIButton) {
        callback?()
    }

    enum Base {
        case top, bottom
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createSubViews()
    }

    init(title: String,
         description: String,
         image: UIImage?,
         titleOfButton: String?,
         buttonAction: ButtonActionBlock?,
         dismissAction: DismissActionBlock? = nil) {
        super.init(frame: CGRect.zero)
        self.createSubViews()

        self.titleLabel.text = title
        self.descriptionLabel.text = description
        self.imageView.image = image
        self.callback = buttonAction
        self.button.setTitle(titleOfButton, for: .normal)
        self.dismissAction = dismissAction

        self.layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.createSubViews()
    }

    private func createSubViews() {
        // set bg color of view
        self.backgroundColor = UIColor(hexColorCode: "#FFFFFF")

        // add gray part of the view on top
        self.topBGView = UIView()
        self.topBGView.backgroundColor = ColorProvider.BackgroundSecondary
        self.topBGView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.topBGView)

        NSLayoutConstraint.activate([
            self.topBGView.topAnchor.constraint(equalTo: self.topAnchor),
            self.topBGView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.topBGView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.topBGView.heightAnchor.constraint(equalToConstant: 160)
        ])

        // Add dismiss icon + callback
        if let image = UIImage(named: "mail_label_cross_icon") {
            let tintableImage = image.withRenderingMode(.alwaysTemplate)
            let dismissImageView = UIImageView(image: tintableImage)
            dismissImageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            dismissImageView.tintColor = ColorProvider.IconNorm
            dismissImageView.isUserInteractionEnabled = true
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
            dismissImageView.addGestureRecognizer(tapRecognizer)
            dismissImageView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(dismissImageView)

            NSLayoutConstraint.activate([
                dismissImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 24),
                dismissImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                dismissImageView.widthAnchor.constraint(equalToConstant: 24),
                dismissImageView.heightAnchor.constraint(equalToConstant: 24)
            ])
        }

        self.imageView = UIImageView(image: UIImage(named: "es-icon"))
        self.addSubview(self.imageView)

        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 18),
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 118.64),
            self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -77.42)
        ])

        self.titleLabel = UILabel()
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textAlignment = .center
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        self.titleLabel.textColor = ColorProvider.TextNorm
        self.addSubview(self.titleLabel)

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 42),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ])

        self.descriptionLabel = UILabel()
        self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionLabel.textAlignment = .center
        self.descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        self.descriptionLabel.textColor = ColorProvider.TextWeak
        self.descriptionLabel.numberOfLines = 3
        self.addSubview(self.descriptionLabel)

        NSLayoutConstraint.activate([
            self.descriptionLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 8),
            self.descriptionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.descriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ])

        self.button = UIButton()
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        self.button.titleLabel?.numberOfLines = 1
        self.button.setTitleColor(ColorProvider.BackgroundNorm, for: .normal)
        self.button.tintColor = ColorProvider.BrandNorm
        self.button.backgroundColor = ColorProvider.BrandNorm
        self.button.layer.cornerRadius = 8
        self.addSubview(self.button)

        NSLayoutConstraint.activate([
            self.button.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 16),
            self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            self.button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
            self.button.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}

extension PopUpView {
    func popUp(on baseView: UIView, from: Base) {
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
