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

import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

protocol MaxStorageTableViewCellDelegate: AnyObject {
    func upgradeStorageTapped()
}

class MaxStorageTableViewCell: UITableViewCell, AccessibleCell {
    private var icon: UIImageView!
    private var labelsStack: UIStackView!
    private var title: UILabel!
    private var caption: UILabel!
    private var ctaButton: UIButton!
    private weak var delegate: MaxStorageTableViewCellDelegate?

    enum Constants {
        static let iconSize: CGFloat = 24
        static let itemsSpacing: CGFloat = 13
        static let cellPadding: CGFloat = 17.5
        static let buttonPadding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.isUserInteractionEnabled = true
        setupIconUI()
        setupLabelsUI()
        setupButtonUI()
        setupSeparatorsUI()
    }

    func configure(storagePercentage: CGFloat, delegate: MaxStorageTableViewCellDelegate?) {
        title.text = String(
            format: L11n.SideMenuStorageAlert.alertBoxTitle,
            storagePercentageString(storagePercentage: storagePercentage)
        )
        self.delegate = delegate
    }

    @objc
    private func upgradeButtonTapped() {
        delegate?.upgradeStorageTapped()
    }

    private func setupIconUI() {
        icon = UIImageView(image: IconProvider.fullStorageWhite)
        icon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(icon)

        [
            icon.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            icon.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.cellPadding)
        ].activate()
    }

    private func setupLabelsUI() {
        labelsStack = UIStackView()
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .vertical

        title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textColor = ColorProvider.SidebarTextNorm
        title.font = UIFont.preferredFont(for: .subheadline, weight: .regular)
        labelsStack.addArrangedSubview(title)

        caption = UILabel()
        caption.translatesAutoresizingMaskIntoConstraints = false
        caption.text = L11n.SideMenuStorageAlert.alertBoxCaption
        caption.textColor = ColorProvider.SidebarTextWeak
        caption.font = UIFont.preferredFont(for: .caption1, weight: .regular)
        labelsStack.addArrangedSubview(caption)

        contentView.addSubview(labelsStack)

        [
            labelsStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: Constants.itemsSpacing),
            labelsStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ].activate()
    }

    private func setupButtonUI() {
        ctaButton = UIButton(type: .custom)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitle(L11n.SideMenuStorageAlert.upgradeButtonTitle, for: .normal)
        ctaButton.titleLabel?.font = UIFont.preferredFont(for: .caption1, weight: .regular)
        ctaButton.tintColor = ColorProvider.TextInverted
        ctaButton.layer.cornerRadius = 8
        ctaButton.backgroundColor = ColorProvider.SidebarInteractionWeakNorm
        ctaButton.contentEdgeInsets = Constants.buttonPadding
        ctaButton.addTarget(self, action: #selector(upgradeButtonTapped), for: .touchUpInside)
        contentView.addSubview(ctaButton)

        [
            ctaButton.leadingAnchor.constraint(greaterThanOrEqualTo: labelsStack.trailingAnchor, constant: 8),
            ctaButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ctaButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.cellPadding)
        ].activate()
    }

    private func setupSeparatorsUI() {
        let topSeparator = UIView()
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        topSeparator.backgroundColor = ColorProvider.SidebarSeparator
        contentView.addSubview(topSeparator)

        [
            topSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 1),
            topSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topSeparator.topAnchor.constraint(equalTo: contentView.topAnchor)
        ].activate()

        let bottomSeparator = UIView()
        bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparator.backgroundColor = ColorProvider.SidebarSeparator
        contentView.addSubview(bottomSeparator)

        [
            bottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 1),
            bottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

    private func storagePercentageString(storagePercentage: CGFloat) -> String {
        percentFormatter.string(from: NSNumber(value: storagePercentage)) ?? ""
    }

    private var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.multiplier = 100
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
