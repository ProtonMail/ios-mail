// Copyright (c) 2025 Proton Technologies AG
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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI
import UIKit

final class ContactCell: UITableViewCell {
    let avatarLabel: UILabel = {
        let label = UILabel()
        label.font = .font(textStyle: .footnote, weight: .semibold)
        label.textColor = UIColor(DS.Color.Text.inverted)
        label.textAlignment = .center
        label.layer.cornerRadius = ContactConstant.avatarRadius
        label.layer.masksToBounds = true
        return label
    }()

    let labelsView = ContactLabelsView()

    // MARK: - UITableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpSelf()
        setupUI()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Private

    private let contentStackView: UIStackView = ViewsFactory.contactItemStackView

    private func setUpSelf() {
        contentView.backgroundColor = UIColor(DS.Color.BackgroundInverted.secondary)
        selectionStyle = .none
    }

    private func setupUI() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.addArrangedSubview(avatarLabel)
        contentStackView.addArrangedSubview(labelsView)

        contentView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            avatarLabel.widthAnchor.constraint(equalToConstant: 40),
            avatarLabel.heightAnchor.constraint(equalTo: avatarLabel.widthAnchor),
        ])
    }
}
