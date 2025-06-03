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
    private let checked = SubviewFactory.checked

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
        setUpConstraints()
    }

    required init?(coder: NSCoder) { nil }

    private func setUpUI() {
        backgroundColor = DS.Color.Background.norm.toDynamicUIColor
        [initials, groupIcon].forEach(avatarView.addSubview)
        [avatarView, labelsView, checked].forEach(contentView.addSubview)
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.large),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            labelsView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            labelsView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.medium),
            labelsView.trailingAnchor.constraint(equalTo: checked.leadingAnchor, constant: -DS.Spacing.large),
            labelsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.medium),

            checked.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.large),
            checked.centerYAnchor.constraint(equalTo: centerYAnchor),
            checked.widthAnchor.constraint(equalToConstant: 24),
            checked.heightAnchor.constraint(equalToConstant: 24),
        ])

        [initials, groupIcon].forEach {
            NSLayoutConstraint.activate([
                $0.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
                $0.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            ])
        }
    }

    func configure(uiModel: ComposerContactUIModel) {
        avatarView.backgroundColor = UIColor(uiModel.avatarColor)
        initials.text = uiModel.isGroup ? "" : uiModel.avatar.initials
        groupIcon.isHidden = !uiModel.isGroup
        labelsView.configure(
            title: uiModel.title,
            subtitle: uiModel.subtitle,
            isSelected: uiModel.alreadySelected
        )
        checked.isHidden = !uiModel.alreadySelected
        isUserInteractionEnabled = !uiModel.alreadySelected
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
            view.textColor = DS.Color.Text.inverted.toDynamicUIColor
            view.textAlignment = .center
            return view
        }

        static var image: UIImageView {
            let view = UIImageView(image: UIImage(resource: DS.Icon.icUsers))
            view.translatesAutoresizingMaskIntoConstraints = false
            view.contentMode = .scaleAspectFit
            view.tintColor = DS.Color.Text.inverted.toDynamicUIColor
            return view
        }

        static var checked: UIImageView {
            let view = UIImageView(image: UIImage(resource: DS.Icon.icCheckmark))
            view.translatesAutoresizingMaskIntoConstraints = false
            view.contentMode = .scaleAspectFit
            view.tintColor = DS.Color.Icon.accent.toDynamicUIColor
            return view
        }
    }
}

private final class LabelsView: UIView {
    private let stack = SubviewFactory.stack
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

    func configure(title: String, subtitle: String, isSelected: Bool) {
        self.title.text = title
        self.title.textColor = isSelected ? DS.Color.Text.hint.toDynamicUIColor : DS.Color.Text.norm.toDynamicUIColor
        self.subtitle.text = subtitle
    }
}

private extension LabelsView {

    private enum SubviewFactory {
        static var titleLabel: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            return view
        }

        static var subtitleLabel: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textColor = DS.Color.Text.weak.toDynamicUIColor
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
