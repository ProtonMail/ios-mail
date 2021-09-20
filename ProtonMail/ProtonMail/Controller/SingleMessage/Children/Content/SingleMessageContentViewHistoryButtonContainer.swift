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

import UIKit

final class SingleMessageContentViewHistoryButtonContainer: UIView {
    let showHideHistoryButton = UIButton(image: Asset.messageExpandCollapse.image)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        nil
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
