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
import InboxCoreUI
import UIKit

final class ContactPickerCell: UITableViewCell {
    private let avatarView = SubviewFactory.avatarView
    private let initials = SubviewFactory.label
    private let groupIcon = SubviewFactory.image
    private let labelsView = LabelsView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
        setUpConstraints()
    }

    required init?(coder: NSCoder) { nil }

    private func setUpUI() {
        [initials, groupIcon].forEach(avatarView.addSubview)
        [avatarView, labelsView].forEach(contentView.addSubview)
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.large),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            labelsView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            labelsView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.medium),
            labelsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.large),
            labelsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.medium),
        ])

        [initials, groupIcon].forEach {
            NSLayoutConstraint.activate([
                $0.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
                $0.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            ])
        }
    }

    func configure(contact: ComposerContact) {
        avatarView.backgroundColor = UIColor(contact.uiModel.avatarColor)
        initials.text = contact.uiModel.isGroup ? "" : contact.uiModel.avatar.initials
        groupIcon.isHidden = !contact.uiModel.isGroup
        labelsView.configure(title: contact.uiModel.title, subtitle: contact.uiModel.subtitle)
    }
}

extension ContactPickerCell {

    enum SubviewFactory {

        static var avatarView: UIView {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = 20
            view.clipsToBounds = true
            return view
        }

        static var label: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textColor = UIColor(DS.Color.Text.inverted)
            view.textAlignment = .center
            return view
        }

        static var image: UIImageView {
            let view = UIImageView(image: UIImage(resource: DS.Icon.icUsers))
            view.translatesAutoresizingMaskIntoConstraints = false
            view.contentMode = .scaleAspectFit
            view.tintColor = UIColor(DS.Color.Text.inverted)
            return view
        }
    }
}


private final class LabelsView: UIView {
    private let stack = SubviewFactory.stack
    private let icon = SubviewFactory.icon
    private let title = SubviewFactory.titleLabel
    private let subtitle = SubviewFactory.subtitleLabel

    init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize {
        stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    func configure(title: String, subtitle: String) {
        self.title.text = title
        self.subtitle.text = subtitle
    }
}


private extension LabelsView {

    private enum SubviewFactory {
        static var icon: UIImageView {
            let view = UIImageView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        static var titleLabel: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textColor = UIColor(DS.Color.Text.weak)
            return view
        }

        static var subtitleLabel: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textColor = UIColor(DS.Color.Text.hint)
            return view
        }

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis = .vertical
            view.alignment = .leading
            view.spacing = DS.Spacing.small
            view.directionalLayoutMargins = .init(top: 0, leading: DS.Spacing.mediumLight, bottom: 0, trailing: DS.Spacing.mediumLight)
            view.isLayoutMarginsRelativeArrangement = true
            return view
        }
    }
}
