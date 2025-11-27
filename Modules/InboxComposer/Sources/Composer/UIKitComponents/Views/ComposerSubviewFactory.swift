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

enum ComposerSubviewFactory {
    static var regularFieldStack: UIStackView {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .center
        view.spacing = DS.Spacing.standard
        view.directionalLayoutMargins = .init(top: 0, leading: DS.Spacing.large, bottom: 0, trailing: DS.Spacing.standard)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    static var fieldTitle: UILabel {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.preferredFont(forTextStyle: .subheadline)
        view.textColor = DS.Color.Text.weak.toDynamicUIColor
        return view
    }

    static var regularLabel: UILabel {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.preferredFont(forTextStyle: .subheadline)
        view.textColor = regularComponentColor
        return view
    }

    static var regularTextField: UITextField {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.preferredFont(forTextStyle: .subheadline)
        view.textColor = regularComponentColor
        view.autocorrectionType = .no
        view.spellCheckingType = .no
        view.tintColor = DS.Color.Icon.accent.toDynamicUIColor
        return view
    }

    static var chevronButton: UIButton {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tintColor = DS.Color.Icon.hint.toDynamicUIColor
        view.contentMode = .scaleAspectFit
        view.setImage(UIImage(resource: DS.Icon.icChevronTinyDown), for: .normal)
        return view
    }

    private static var regularComponentColor: UIColor {
        DS.Color.Text.norm.toDynamicUIColor
    }
}
