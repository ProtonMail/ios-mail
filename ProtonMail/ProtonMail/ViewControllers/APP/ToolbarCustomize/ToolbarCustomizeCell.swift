// Copyright (c) 2022 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

protocol ToolbarCustomizeCellDelegate: AnyObject {
    func handleAction(action: ToolbarCustomizeCell.Action, indexPath: IndexPath)
}

final class ToolbarCustomizeCell: UITableViewCell {
    static let reuseID = "ToolbarCustomizeCell"

    enum Action {
        case insert
        case remove

        var color: UIColor {
            switch self {
            case .insert:
                return ColorProvider.NotificationSuccess
            case .remove:
                return ColorProvider.NotificationError
            }
        }
    }

    private(set) var action: Action?
    let iconView = SubviewsFactory.iconView
    let actionButton = SubviewsFactory.actionButton
    let titleLabel = SubviewsFactory.titleLabel
    weak var delegate: ToolbarCustomizeCellDelegate?
    private(set) var indexPath: IndexPath?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubviews()
        setupLayout()
        setupButton()

        contentView.backgroundColor = ColorProvider.BackgroundNorm
        backgroundColor = ColorProvider.BackgroundNorm
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        addSeparator(padding: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure<T>(toolbarAction: T,
                      action: Action,
                      indexPath: IndexPath,
                      enable: Bool) where T: ToolbarAction {
        switch action {
        case .insert:
            actionButton.setImage(IconProvider.plusCircleFilled, for: .normal)
            actionButton.imageView?.tintColor = action.color
        case .remove:
            actionButton.setImage(Asset.icMinusCircleFilled.image, for: .normal)
            actionButton.imageView?.tintColor = action.color
        }
        self.action = action
        self.indexPath = indexPath
        iconView.image = toolbarAction.icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = ColorProvider.IconNorm

        var attribute = FontManager.Default
        attribute[.font] = UIFont.adjustedFont(forTextStyle: .subheadline)
        titleLabel.attributedText = toolbarAction.title?.apply(style: attribute)

        if enable {
            isUserInteractionEnabled = true
            contentView.alpha = 1.0
        } else {
            isUserInteractionEnabled = false
            contentView.alpha = 0.5
        }
    }

    private func addSubviews() {
        contentView.addSubview(iconView)
        contentView.addSubview(actionButton)
        contentView.addSubview(titleLabel)
    }

    private func setupLayout() {
        [
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionButton.heightAnchor.constraint(equalToConstant: 24),
            actionButton.widthAnchor.constraint(equalToConstant: 24),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ].activate()

        [
            iconView.leadingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ].activate()
    }

    private func setupButton() {
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    @objc
    private func actionButtonTapped() {
        guard let action = self.action,
              let indexPath = self.indexPath else {
            return
        }
        delegate?.handleAction(action: action, indexPath: indexPath)
    }
}

private enum SubviewsFactory {
    static var actionButton: UIButton {
        let button = UIButton()
        return button
    }

    static var iconView: UIImageView {
        let view = UIImageView()
        view.tintColor = ColorProvider.IconNorm
        return view
    }

    static var titleLabel: UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }
}
