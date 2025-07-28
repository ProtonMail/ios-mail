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

final class RecipientsFieldIdleController: UIViewController {
    enum Layout {
        static let minCellHeight: CGFloat = 32.0
    }
    private let recipientView = RecipientChipView()
    private let extraRecipientsCount = ExtraRecipientsCountView()
    private var recipient: RecipientUIModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        extraRecipientsCount.isHidden = true
        [recipientView, extraRecipientsCount].forEach(view.addSubview)
    }

    func setUpConstraints() {
        let verticalSpacing = DS.Spacing.small
        extraRecipientsCount.setContentHuggingPriority(.required, for: .horizontal)
        extraRecipientsCount.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: Layout.minCellHeight + 2 * verticalSpacing),
            recipientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recipientView.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalSpacing),
            recipientView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalSpacing),
            extraRecipientsCount.leadingAnchor.constraint(equalTo: recipientView.trailingAnchor, constant: DS.Spacing.small),
            extraRecipientsCount.centerYAnchor.constraint(equalTo: recipientView.centerYAnchor),
            extraRecipientsCount.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recipientView.recipient = recipient
    }

    func configure(recipient: RecipientUIModel?, numExtra: Int) {
        self.recipient = recipient
        recipientView.recipient = recipient
        extraRecipientsCount.configure(extraNumber: numExtra)
    }
}
