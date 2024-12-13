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

import InboxCore
import InboxDesignSystem
import UIKit

final class ExtraRecipientsCountView: UIView {
    let label = SubviewFactory.extraRecipients

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Private

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DS.Spacing.mediumLight),
            label.topAnchor.constraint(equalTo: topAnchor, constant: DS.Spacing.compact),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DS.Spacing.mediumLight),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DS.Spacing.compact),
        ])

        applyCGColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyCGColors()
        }
    }

    private func applyCGColors() {
        layoutIfNeeded()
        layer.borderWidth = 1
        layer.masksToBounds = true
        layer.cornerRadius = frame.height / 2.0
        layer.borderColor = UIColor(DS.Color.Border.norm).cgColor
    }

    func configure(extraNumber: Int) {
        label.text = extraNumber > 0 ? Strings.plus(count: extraNumber) : ""
        isHidden = extraNumber < 1
        applyCGColors()
    }
}

extension ExtraRecipientsCountView {

    private enum SubviewFactory {

        static var extraRecipients: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textColor = UIColor(DS.Color.Text.norm)
            view.textAlignment = .center
            return view
        }
    }
}
