//
//  NewMailboxMessageContentView.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class NewMailboxMessageContentView: BaseMessageView {

    let contentStackView = SubviewsFactory.verticalStackView
    let firstLineStackView = SubviewsFactory.horizontalStackView
    let draftImageView = SubviewsFactory.draftImageView
    let secondLineStackView = SubviewsFactory.horizontalStackView
    let titleLabel = UILabel(frame: .zero)
    let messageCountLabel = SubviewsFactory.messageCountLabel
    let originalImagesStackView = SubviewsFactory.horizontalStackView

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    func addTagsView() {
        tagsView.isHidden = false
    }

    func removeTagsView() {
        tagsView.isHidden = true
    }

    func removeOriginImages() {
        originalImagesStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
    }

    private func addSubviews() {
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(firstLineStackView)
        firstLineStackView.addArrangedSubview(replyImageView)
        firstLineStackView.addArrangedSubview(replyAllImageView)
        firstLineStackView.addArrangedSubview(forwardImageView)
        firstLineStackView.addArrangedSubview(draftImageView)
        firstLineStackView.addArrangedSubview(sendersStackView)
        firstLineStackView.addArrangedSubview(UIView())
        firstLineStackView.addArrangedSubview(StackViewContainer(view: timeLabel, bottom: -2))

        contentStackView.addArrangedSubview(secondLineStackView)
        secondLineStackView.addArrangedSubview(originalImagesStackView)
        secondLineStackView.addArrangedSubview(StackViewContainer(view: titleLabel, bottom: -2))
        secondLineStackView.addArrangedSubview(messageCountLabel)
        secondLineStackView.addArrangedSubview(UIView())
        secondLineStackView.addArrangedSubview(attachmentImageView)
        secondLineStackView.addArrangedSubview(starImageView)

        contentStackView.addArrangedSubview(tagsView)
    }

    private func setUpLayout() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        [
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
            .activate()

        [titleLabel].forEach { view in
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        let heightConstraint = messageCountLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20.0)
        heightConstraint.priority = .defaultHigh
        [heightConstraint].activate()

        [
            starImageView.widthAnchor.constraint(equalToConstant: 16.0),
            starImageView.heightAnchor.constraint(equalToConstant: 16.0).setPriority(as: .defaultHigh),
            attachmentImageView.widthAnchor.constraint(equalToConstant: 16.0),
            attachmentImageView.heightAnchor.constraint(equalToConstant: 16.0),
            forwardImageView.widthAnchor.constraint(equalToConstant: 16.0),
            forwardImageView.heightAnchor.constraint(equalToConstant: 16.0),
            replyImageView.widthAnchor.constraint(equalToConstant: 16.0),
            replyImageView.heightAnchor.constraint(equalToConstant: 16.0),
            replyAllImageView.widthAnchor.constraint(equalToConstant: 16.0),
            replyAllImageView.heightAnchor.constraint(equalToConstant: 16.0),
            draftImageView.widthAnchor.constraint(equalToConstant: 16.0),
            draftImageView.heightAnchor.constraint(equalToConstant: 16.0),
            firstLineStackView.heightAnchor.constraint(equalTo: timeLabel.heightAnchor, constant: 2)
        ].activate()

        [
            originalImagesStackView,
            timeLabel,
            replyImageView,
            forwardImageView,
            draftImageView,
            attachmentImageView,
            starImageView
        ].forEach { view in
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }

        contentStackView.setCustomSpacing(2, after: firstLineStackView)
        contentStackView.setCustomSpacing(12, after: secondLineStackView)
        secondLineStackView.setCustomSpacing(8, after: sendersStackView)
    }

    required init?(coder: NSCoder) {
        nil
    }
}

private extension NewMailboxMessageContentView {
    private class SubviewsFactory: BaseMessageView.SubviewsFactory {
        static var horizontalStackView: UIStackView {
            .stackView(alignment: .center, spacing: 4)
        }

        static var verticalStackView: UIStackView {
            .stackView(axis: .vertical)
        }

        static var messageCountLabel: PaddingLabel {
            let label = PaddingLabel(withInsets: 0, 0, 6, 6)
            label.layer.cornerRadius = 3
            label.layer.borderWidth = 1
            label.layer.borderColor = ColorProvider.TextNorm
            return label
        }
    }
}
