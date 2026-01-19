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
    private let button = UIButton(type: .custom)
    private var widthConstraint: NSLayoutConstraint?

    var onCopy: (() -> Void)?
    var onRemove: (() -> Void)?

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
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = true
        button.addSubview(recipientView)
        contentView.addSubview(button)
    }

    private func setUpConstraints() {
        widthConstraint = contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 0)
        widthConstraint?.priority = .defaultHigh
        widthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            recipientView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            recipientView.topAnchor.constraint(equalTo: button.topAnchor),
            recipientView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            recipientView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
    }

    func configure(maxWidth: CGFloat) {
        widthConstraint?.constant = maxWidth
    }

    func configure(with recipient: RecipientUIModel, maxWidth: CGFloat) {
        self.recipient = recipient
        configure(maxWidth: maxWidth)
    }

    private func configureContextMenu(with recipient: RecipientUIModel) {
        let remove = UIAction.remove(action: { [weak self] _ in self?.onRemove?() })
        var actions: [UIAction] = []
        switch recipient.type {
        case .single:
            let copy = UIAction.copy(action: { [weak self] _ in self?.onCopy?() })
            actions = [copy, remove]
        case .group:
            actions = [remove]
        }

        button.menu = UIMenu(children: actions)
    }
}

private extension UIAction {
    static func copy(action: @escaping (UIAction) -> Void) -> UIAction {
        UIAction(
            title: L10n.Composer.recipientMenuCopy.string,
            image: UIImage(systemName: "doc.on.doc"),  // FIXME: - Use correct icon
            handler: action
        )
    }

    static func remove(action: @escaping (UIAction) -> Void) -> UIAction {
        UIAction(
            title: L10n.Composer.recipientMenuRemove.string,
            image: UIImage(systemName: "trash"),  // FIXME: - Use correct icon
            attributes: .destructive,
            handler: action
        )
    }
}
