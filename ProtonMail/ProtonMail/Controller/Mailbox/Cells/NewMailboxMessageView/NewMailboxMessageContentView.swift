//
//  NewMailboxMessageContentView.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class NewMailboxMessageContentView: UIView {

    let contentStackView = SubviewsFactory.verticalStackVIew
    let firstLineStackView = SubviewsFactory.horizontalStackView
    let replyImageView = SubviewsFactory.replyImageView
    let replyAllImageView = SubviewsFactory.replyAllImageView
    let forwardImageView = SubviewsFactory.forwardImageView
    let draftImageView = SubviewsFactory.draftImageView
    let senderLabel = SubviewsFactory.senderLabel
    let timeLabel = UILabel(frame: .zero)
    let secondLineStackView = SubviewsFactory.horizontalStackView
    let titleLabel = UILabel(frame: .zero)
    let attachmentImageView = SubviewsFactory.attachmentImageView
    let starImageView = SubviewsFactory.startImageView
    let tagsView = SingleRowTagsView()
    let messageCountLabel = SubviewsFactory.messageCountLabel
    let originalImagesStackView = SubviewsFactory.horizontalStackView

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    func addTagsView() {
        contentStackView.addArrangedSubview(tagsView)
    }

    func removeTagsView() {
        contentStackView.removeArrangedSubview(tagsView)
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
        firstLineStackView.addArrangedSubview(StackViewContainer(view: senderLabel, bottom: -4))
        firstLineStackView.addArrangedSubview(UIView())
        firstLineStackView.addArrangedSubview(StackViewContainer(view: timeLabel, bottom: -2))

        contentStackView.addArrangedSubview(secondLineStackView)
        secondLineStackView.addArrangedSubview(originalImagesStackView)
        secondLineStackView.addArrangedSubview(StackViewContainer(view: titleLabel, bottom: -2))
        secondLineStackView.addArrangedSubview(messageCountLabel)
        secondLineStackView.addArrangedSubview(UIView())
        secondLineStackView.addArrangedSubview(attachmentImageView)
        secondLineStackView.addArrangedSubview(starImageView)
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

        [senderLabel, titleLabel].forEach { view in
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        let heightConstraint = messageCountLabel.heightAnchor.constraint(equalToConstant: 20.0)
        heightConstraint.priority = .defaultHigh
        [heightConstraint].activate()

        [
            originalImagesStackView,
            timeLabel,
            replyImageView,
            forwardImageView,
            draftImageView,
            attachmentImageView,
            starImageView
        ].forEach { view in
            view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }

        contentStackView.setCustomSpacing(2, after: firstLineStackView)
        contentStackView.setCustomSpacing(12, after: secondLineStackView)
        secondLineStackView.setCustomSpacing(8, after: senderLabel)
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var horizontalStackView: UIStackView {
        .stackView(alignment: .center, spacing: 4)
    }

    static var verticalStackVIew: UIStackView {
        .stackView(axis: .vertical)
    }

    static var forwardImageView: UIImageView {
        imageView(Asset.mailForward.image)
    }

    static var replyImageView: UIImageView {
        imageView(Asset.mailReply.image)
    }

    static var replyAllImageView: UIImageView {
        imageView(Asset.mailReplyAll.image)
    }

    static var senderLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.textColor = ColorProvider.TextNorm
        return label
    }

    static var attachmentImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = Asset.mailAttachment.image.toTemplateUIImage()
        imageView.tintColor = ColorProvider.IconWeak
        return imageView
    }

    static var startImageView: UIImageView {
        imageView(Asset.mailStar.image)
    }

    static var draftImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = Asset.mailDraftIcon.image
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }

    static var originImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    static func imageView(_ image: UIImage) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        return imageView
    }

    static var messageCountLabel: PaddingLabel {
        let label = PaddingLabel(withInsets: 0, 0, 6, 6)
        label.layer.cornerRadius = 3
        label.layer.borderWidth = 1
        label.layer.borderColor = ColorProvider.TextNorm.cgColor
        return label
    }
}
