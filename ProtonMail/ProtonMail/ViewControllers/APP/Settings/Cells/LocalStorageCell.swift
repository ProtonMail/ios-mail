// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCore_Utilities
import UIKit

final class LocalStorageCell: UITableViewCell {
    private let stackView = SubviewFactory.stackView
    private let titleLabel = SubviewFactory.titleLabel
    private let infoLabel = SubviewFactory.smallLabel
    private let storageLabel = SubviewFactory.storageLabel
    private let buttonStackView = SubviewFactory.buttonStackView
    private let clearButton = SubviewFactory.button
    weak var delegate: LocalStorageCellDelegate?

    private enum Layout {
        static let hMargin = 16.0
        static let vMargin = 12.0
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpView()
        setUpConstraints()
    }

    private func setUpView() {
        clearButton.addTarget(self, action: #selector(onClearTap), for: .touchUpInside)
        [storageLabel, clearButton].forEach {
            buttonStackView.addArrangedSubview($0)
        }
        [titleLabel, infoLabel, buttonStackView].forEach {
            stackView.addArrangedSubview($0)
        }
        contentView.addSubview(stackView)
    }

    private func setUpConstraints() {
        clearButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        [
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

    @objc
    private func onClearTap() {
        delegate?.didTapClear(sender: self)
    }

    func configure(info: LocalStorageInfo) {
        titleLabel.text = info.title
        infoLabel.text = info.message
        storageLabel.text = info.localStorageUsed.toByteCount
        clearButton.isHidden = info.isClearButtonHidden
    }
}

extension LocalStorageCell {

    struct LocalStorageInfo {
        let title: String
        let message: String?
        let localStorageUsed: ByteCount
        let isClearButtonHidden: Bool
    }
}

extension LocalStorageCell {

    private enum SubviewFactory {

        static var defaultLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ColorProvider.TextNorm
            label.numberOfLines = 0
            return label
        }

        static var stackView: UIStackView {
            let stack = UIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .vertical
            stack.distribution = .equalSpacing
            stack.alignment = .fill
            stack.layoutMargins = UIEdgeInsets(
                top: Layout.vMargin,
                left: Layout.hMargin,
                bottom: Layout.vMargin,
                right: Layout.hMargin
            )
            stack.isLayoutMarginsRelativeArrangement = true
            stack.spacing = 8
            return stack
        }

        static var titleLabel: UILabel {
            let label = defaultLabel
            label.font = .adjustedFont(forTextStyle: .headline)
            return label
        }

        static var storageLabel: UILabel {
            let label = defaultLabel
            label.font = .adjustedFont(forTextStyle: .subheadline)
            return label
        }

        static var smallLabel: UILabel {
            let label = defaultLabel
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.textColor = ColorProvider.TextWeak
            return label
        }

        static var buttonStackView: UIStackView {
            let stack = UIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .horizontal
            stack.distribution = .fill
            stack.isLayoutMarginsRelativeArrangement = true
            stack.spacing = 8
            return stack
        }

        static var button: UIButton {
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.backgroundColor = ColorProvider.InteractionWeak
            button.setTitleColor(ColorProvider.TextNorm, for: .normal)
            button.tintColor = ColorProvider.InteractionWeak
            button.titleLabel?.font = .adjustedFont(forTextStyle: .footnote)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.numberOfLines = 1
            button.layer.cornerRadius = 8
            button.setTitle(L11n.EncryptedSearch.downloaded_messages_storage_used_button_title, for: .normal)
            return button
        }
    }
}

protocol LocalStorageCellDelegate: AnyObject {
    func didTapClear(sender: LocalStorageCell)
}
