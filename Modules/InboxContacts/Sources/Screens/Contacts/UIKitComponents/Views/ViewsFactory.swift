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
import SwiftUI
import UIKit

enum ViewsFactory {

    static func label(text: String? = nil, font: UIFont, textColor: Color) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = UIColor(textColor)
        return label
    }

    static var contactItemStackView: UIStackView {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(vertical: DS.Spacing.medium, horizontal: DS.Spacing.large)
        stackView.spacing = DS.Spacing.large

        return stackView
    }

}
