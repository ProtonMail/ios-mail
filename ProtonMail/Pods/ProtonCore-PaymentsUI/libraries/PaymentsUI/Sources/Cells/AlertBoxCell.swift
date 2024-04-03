//
//  AlertBoxCell.swift
//  ProtonCorePaymentsUI - Created on 25.01.24.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)
import UIKit
import ProtonCoreUIFoundations

class AlertBoxCell: UITableViewCell {
    static let reuseIdentifier = "AlertBoxCell"

    private let mainView = UIView()
    private let iconContentView = UIView()
    private let iconImageView = UIImageView()
    private let textStackView = UIStackView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let alertActionButton = UIButton()
    private var alertAction: (() -> Void)?

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        isUserInteractionEnabled = true
        backgroundColor = .clear
    }

    func configure(with viewModel: AlertBoxViewModel, action: (() -> Void)?) {
        self.alertAction = action
        setupMainView()
        setupIconImagView()
        setupTextStackView(viewModel: viewModel)
        setupHorizontalStackView()
    }

    private func setupMainView() {
        contentView.addSubview(mainView)
        mainView.layer.cornerRadius = 12.0
        mainView.layer.borderWidth = 1.0
        mainView.layer.borderColor = ColorProvider.InteractionNorm

        mainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func setupIconImagView() {
        iconImageView.image = IconProvider.fullStorage
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        iconContentView.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconContentView.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            iconContentView.leadingAnchor.constraint(equalTo: iconImageView.leadingAnchor),
            iconContentView.trailingAnchor.constraint(equalTo: iconImageView.trailingAnchor)
        ])
    }

    private func setupTitleLabel(title: String) {
        titleLabel.text = title
        titleLabel.font = .adjustedFont(forTextStyle: .body, weight: .bold)
        titleLabel.textColor = ColorProvider.TextNorm
        titleLabel.numberOfLines = 0
    }

    private func setupDescriptionLabel(description: String) {
        descriptionLabel.text = description
        descriptionLabel.font = .adjustedFont(forTextStyle: .body)
        descriptionLabel.textColor = ColorProvider.TextWeak
        descriptionLabel.numberOfLines = 0
    }

    private func setupAlertActionButton(buttonTitle: String) {
        alertActionButton.setTitle(buttonTitle, for: .normal)
        alertActionButton.setTitleColor(ColorProvider.InteractionNorm, for: .normal)
        alertActionButton.addTarget(self, action: #selector(onAlertActionButtonTap), for: .touchUpInside)
    }

    @objc private func onAlertActionButtonTap() {
        alertAction?()
    }

    private func setupTextStackView(viewModel: AlertBoxViewModel) {
        setupTitleLabel(title: viewModel.title)
        setupDescriptionLabel(description: viewModel.description)
        setupAlertActionButton(buttonTitle: viewModel.buttonTitle)

        textStackView.axis = .vertical
        textStackView.spacing = 8
        textStackView.distribution = .fill
        textStackView.alignment = .leading
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)
        textStackView.addArrangedSubview(alertActionButton)
    }

    private func setupHorizontalStackView() {
        let horizontalStackView = UIStackView(arrangedSubviews: [iconContentView, textStackView])
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 8

        mainView.addSubview(horizontalStackView)

        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 16),
            horizontalStackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 16),
            horizontalStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -16),
            horizontalStackView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: -16)
        ])
    }
}

#endif
