//
//  BioCodeView.swift
//  Proton Mail - Created on 19/09/2019.
//
//
//  Copyright (c) 2019 Proton AG
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
import ProtonCore_UIFoundations

protocol BioCodeViewDelegate: AnyObject {
    func touch_id_action(_ sender: Any)
}

final class BioCodeView: UIView {
    let bioButton = SubviewFactory.bioButton
    let upperSpace = UIView()
    let iconView = SubviewFactory.iconView
    let titleLabel = SubviewFactory.titleLabel
    let buttonContainer = UIView()

    weak var delegate: BioCodeViewDelegate?

    @objc
    private func touchIDTapped(_ sender: Any) {
        delegate?.touch_id_action(sender)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        setupLayout()
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubviews()
        setupLayout()
        setup()
    }

    private func addSubviews() {
        addSubview(upperSpace)
        addSubview(buttonContainer)
        addSubview(iconView)
        addSubview(titleLabel)
        buttonContainer.addSubview(bioButton)
    }

    private func setupLayout() {
        [
            upperSpace.trailingAnchor.constraint(equalTo: trailingAnchor),
            upperSpace.leadingAnchor.constraint(equalTo: leadingAnchor),
            upperSpace.topAnchor.constraint(equalTo: topAnchor),
            upperSpace.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.333_583)
        ].activate()

        [
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),
            iconView.topAnchor.constraint(equalTo: upperSpace.bottomAnchor),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ].activate()

        [
            buttonContainer.heightAnchor.constraint(equalToConstant: 170),
            buttonContainer.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 70),
            buttonContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonContainer.leadingAnchor.constraint(equalTo: leadingAnchor)
        ].activate()

        [
            bioButton.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            bioButton.widthAnchor.constraint(equalToConstant: 50),
            bioButton.heightAnchor.constraint(equalToConstant: 50),
            bioButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32)

        ].activate()

        bioButton.addTarget(self,
                            action: #selector(touchIDTapped(_:)),
                            for: .touchUpInside)
    }

    func setup() {
        backgroundColor = ColorProvider.BackgroundNorm
        bioButton.alpha = 0.0
        bioButton.isEnabled = false
        bioButton.layer.cornerRadius = 25

        switch UIDevice.current.biometricType {
        case .faceID:
            bioButton.setImage(IconProvider.faceId, for: .normal)
            bioButton.isHidden = false

        case .touchID:
            bioButton.setImage(IconProvider.touchId, for: .normal)
            bioButton.isHidden = false

        case .none:
            bioButton.isHidden = true
        }
    }

    func loginCheck(_ flow: SignInUIFlow) {
        switch flow {
        case .requirePin:
            if userCachedStatus.isTouchIDEnabled {
                bioButton.alpha = 1.0
                bioButton.isEnabled = true
            }
        case .requireTouchID:
            bioButton.alpha = 1.0
            bioButton.isEnabled = true

        case .restore:
            break
        }
    }

    func showErrorAndQuit() {
        bioButton.alpha = 0.0
    }
}

private enum SubviewFactory {
    static var bioButton: UIButton {
        let button = UIButton()
        button.setImage(Asset.touchIdIcon.image, for: .normal)
        button.imageView?.tintColor = ColorProvider.IconNorm
        return button
    }

    static var iconView: UIImageView {
        let view = UIImageView(image: IconProvider.mailMainTransparent)
        view.contentMode = .scaleAspectFit
        return view
    }

    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.text = "Proton Mail"
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }
}
