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

import DesignSystem
import ProtonCoreUI
import UIKit

final class ContactLabelsView: UIView {

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .font(textStyle: .body, weight: .regular)
        label.textColor = UIColor(DS.Color.Text.weak)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .body3(weight: .regular)
        label.textColor = UIColor(DS.Color.Text.hint)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = DS.Spacing.small
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Private

    private func setupUI() {
        textStackView.translatesAutoresizingMaskIntoConstraints = false

        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(subtitleLabel)

        addSubview(textStackView)

        NSLayoutConstraint.activate([
            textStackView.topAnchor.constraint(equalTo: topAnchor),
            textStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

}
