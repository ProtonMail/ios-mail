// Copyright (c) 2021 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

final class SingleMessageContentViewHistoryButtonContainer: UIView {
    let showHideHistoryButton = UIButton(image: IconProvider.threeDotsHorizontal)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpButtonStyle()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setUpButtonStyle() {
        showHideHistoryButton.tintColor = ColorProvider.IconWeak
        showHideHistoryButton.backgroundColor = ColorProvider.BackgroundNorm
        showHideHistoryButton.layer.borderColor = ColorProvider.SeparatorNorm.cgColor
        showHideHistoryButton.layer.borderWidth = 1.0
        showHideHistoryButton.layer.cornerRadius = 4.0
        showHideHistoryButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }

    private func setUpLayout() {
        addSubview(showHideHistoryButton)
        [
            showHideHistoryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            showHideHistoryButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            showHideHistoryButton.heightAnchor.constraint(equalTo: heightAnchor, constant: -32)
        ].activate()
    }
}
