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

import InboxCoreUI
import SwiftUI
import UIKit

final class RecipientCell: UICollectionViewCell {
    private let recipientView = RecipientChipView()
    private var widthConstraint: NSLayoutConstraint?

    private var recipient: RecipientUIModel? {
        didSet {
            recipientView.recipient = recipient
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
        setUpConstraints()
    }

    required init?(coder: NSCoder) { nil }

    private func setUpView() {
        contentView.addSubview(recipientView)
    }

    private func setUpConstraints() {
        widthConstraint = contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 0)
        widthConstraint?.priority = .defaultHigh
        widthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            recipientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            recipientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            recipientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            recipientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    func configure(maxWidth: CGFloat) {
        widthConstraint?.constant = maxWidth
    }

    func configure(with recipient: RecipientUIModel, maxWidth: CGFloat) {
        self.recipient = recipient
        configure(maxWidth: maxWidth)
    }
}
