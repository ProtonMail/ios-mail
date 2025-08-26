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

final class ContactLabelsView: UIView {

    let titleLabel: UILabel = ViewsFactory.label(
        font: .font(textStyle: .body, weight: .regular), textColor: DS.Color.Text.weak
    )

    let subtitleLabel: UILabel = ViewsFactory.label(
        font: .font(textStyle: .subheadline, weight: .regular),
        textColor: DS.Color.Text.hint
    )

    private let stackView: UIStackView = {
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
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

}
