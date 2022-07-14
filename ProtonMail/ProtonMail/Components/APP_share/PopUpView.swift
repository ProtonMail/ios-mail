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

class PopUpView: PMView {

    private weak var superView: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet weak var topBGView: UIView!

    typealias ButtonActionBlock = () -> Void
    typealias DismissActionBlock = () -> Void

    var callback: ButtonActionBlock?
    var dismissAction: DismissActionBlock?

    @IBAction func buttonPressed(_ sender: UIButton) {
        callback?()
    }

    override func getNibName() -> String {
        return "\(PopUpView.self)"
    }

    enum Base {
        case top, bottom
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

        self.layoutIfNeeded()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension PopUpView {
    // swiftlint:disable function_body_length
    func popUp(on baseView: UIView, from: Base) {
        self.superView = baseView

        // sizing
        let popUpWidth: CGFloat = baseView.bounds.width
        let popUpHeight: CGFloat = 276.0

        let size: CGSize = CGSize(width: popUpWidth, height: popUpHeight)
        self.frame = CGRect(origin: .zero, size: size)

        // add gray part of the view on top
        self.topBGView.backgroundColor = ColorProvider.BackgroundSecondary
        self.topBGView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topBGView.topAnchor.constraint(equalTo: self.topAnchor),
            self.topBGView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.topBGView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.topBGView.heightAnchor.constraint(equalToConstant: 160)
        ])
        // set bg color of view
        self.backgroundColor = UIColor(hexColorCode: "#FFFFFF")

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

        // Set constraints for the individual elements
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 18),
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 118.64),
            self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -77.42)
        ])

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textAlignment = .center
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        self.titleLabel.textColor = ColorProvider.TextNorm
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 42),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ])

        self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionLabel.textAlignment = .center
        self.descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        self.descriptionLabel.textColor = ColorProvider.TextWeak
        self.descriptionLabel.numberOfLines = 3
        NSLayoutConstraint.activate([
            self.descriptionLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 8),
            self.descriptionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.descriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ])

        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        self.button.titleLabel?.numberOfLines = 1
        self.button.setTitleColor(ColorProvider.BackgroundNorm, for: .normal)
        self.button.tintColor = ColorProvider.BrandNorm
        self.button.backgroundColor = ColorProvider.BrandNorm
        self.button.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            self.button.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 16),
            self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            self.button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
            self.button.heightAnchor.constraint(equalToConstant: 48)
        ])

        self.layoutIfNeeded()
    }

    func remove() {
        self.removeFromSuperview()
    }

    @objc func dismiss(_ sender: UITapGestureRecognizer) {
        self.remove()
        self.dismissAction?()
    }
}
