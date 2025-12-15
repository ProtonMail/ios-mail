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

final class NoContactsPlaceholderView: UIView {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(resource: DS.Images.noContacts))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = ViewsFactory.label(
        text: L10n.Contacts.EmptyState.title.string,
        font: .font(textStyle: .title2, weight: .semibold),
        textColor: DS.Color.Text.weak
    )

    private let subtitleLabel: UILabel = ViewsFactory.label(
        text: L10n.Contacts.EmptyState.subtitle.string,
        font: .font(textStyle: .subheadline, weight: .regular),
        textColor: DS.Color.Text.weak
    )

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = DS.Spacing.compact
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Private

    private func setupUI() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        stackView.setCustomSpacing(DS.Spacing.large, after: iconImageView)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 128),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}
