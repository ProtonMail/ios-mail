// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import InboxDesignSystem
import UIKit

final class CheckableIconButton: UIButton {
    enum State {
        case unchecked
        case checked
    }

    private let backgroundIcon = UIImageView()
    private let checkmarkIcon = UIImageView()
    private let checkmarkBackground = UIView()

    private let backgroundIconSize = 24.0
    private let checkmarkPositionCorection = 4.0
    private let checkmarkMultiplier = 0.6

    var buttonState: State = .unchecked {
        didSet { updateAppearance() }
    }

    init(icon: ImageResource) {
        super.init(frame: .zero)
        setUpUI()
        setUpConstraints()
        updateAppearance()
        backgroundIcon.image = UIImage(resource: icon).withRenderingMode(.alwaysTemplate)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpUI()
        updateAppearance()
    }

    override var isHighlighted: Bool {
        didSet { updateHighlightAppearance() }
    }

    func setState(_ newState: State) {
        buttonState = newState
    }

    private func setUpUI() {
        backgroundIcon.contentMode = .scaleAspectFit
        checkmarkIcon.contentMode = .scaleAspectFit
        backgroundIcon.tintColor = DS.Color.Icon.hint.toDynamicUIColor
        checkmarkIcon.tintColor = DS.Color.Icon.hint.toDynamicUIColor

        addSubview(backgroundIcon)
        addSubview(checkmarkBackground)
        addSubview(checkmarkIcon)
        backgroundIcon.translatesAutoresizingMaskIntoConstraints = false
        checkmarkBackground.translatesAutoresizingMaskIntoConstraints = false
        checkmarkIcon.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            backgroundIcon.widthAnchor.constraint(equalToConstant: backgroundIconSize),
            backgroundIcon.heightAnchor.constraint(equalToConstant: backgroundIconSize),
            backgroundIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            checkmarkBackground.widthAnchor.constraint(equalTo: backgroundIcon.widthAnchor, multiplier: checkmarkMultiplier),
            checkmarkBackground.heightAnchor.constraint(equalTo: backgroundIcon.heightAnchor, multiplier: checkmarkMultiplier),
            checkmarkBackground.bottomAnchor.constraint(equalTo: backgroundIcon.bottomAnchor, constant: checkmarkPositionCorection),
            checkmarkBackground.trailingAnchor.constraint(equalTo: backgroundIcon.trailingAnchor, constant: checkmarkPositionCorection),
        ])
        checkmarkBackground.backgroundColor = DS.Color.Background.norm.toDynamicUIColor
        checkmarkBackground.layer.cornerRadius = (checkmarkMultiplier / 2) * backgroundIconSize
        checkmarkBackground.layer.masksToBounds = true

        NSLayoutConstraint.activate([
            checkmarkIcon.widthAnchor.constraint(equalTo: backgroundIcon.widthAnchor, multiplier: checkmarkMultiplier),
            checkmarkIcon.heightAnchor.constraint(equalTo: backgroundIcon.heightAnchor, multiplier: checkmarkMultiplier),
            checkmarkIcon.bottomAnchor.constraint(equalTo: backgroundIcon.bottomAnchor, constant: checkmarkPositionCorection),
            checkmarkIcon.trailingAnchor.constraint(equalTo: backgroundIcon.trailingAnchor, constant: checkmarkPositionCorection),
        ])
    }

    private func updateAppearance() {
        switch buttonState {
        case .unchecked:
            backgroundIcon.tintColor = DS.Color.Icon.hint.toDynamicUIColor
            checkmarkIcon.isHidden = true
            checkmarkBackground.isHidden = true
        case .checked:
            backgroundIcon.tintColor = DS.Color.Icon.norm.toDynamicUIColor
            checkmarkIcon.image = UIImage(resource: DS.Icon.icCheckmarkCircleFilled).withRenderingMode(.alwaysTemplate)
            checkmarkIcon.tintColor = DS.Color.Icon.norm.toDynamicUIColor
            checkmarkIcon.isHidden = false
            checkmarkBackground.isHidden = false
        }
        isUserInteractionEnabled = true
        updateHighlightAppearance()
    }

    private func updateHighlightAppearance() {
        if isHighlighted {
            backgroundIcon.tintColor = DS.Color.Icon.norm.toDynamicUIColor
            checkmarkIcon.tintColor = DS.Color.Icon.norm.toDynamicUIColor
        } else {
            switch buttonState {
            case .unchecked:
                backgroundIcon.tintColor = DS.Color.Icon.hint.toDynamicUIColor
            case .checked:
                backgroundIcon.tintColor = DS.Color.Icon.norm.toDynamicUIColor
                checkmarkIcon.tintColor = DS.Color.Icon.norm.toDynamicUIColor
            }
        }
    }
}
