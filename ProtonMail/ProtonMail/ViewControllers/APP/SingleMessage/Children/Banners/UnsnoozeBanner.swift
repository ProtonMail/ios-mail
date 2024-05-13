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

import ProtonCoreUIFoundations
import UIKit

final class UnsnoozeBanner: UIView {
    private let icon = SubviewsFactory.iconImageView
    let infoLabel = SubviewsFactory.infoLabel
    let unsnoozeButton = SubviewsFactory.unsnoozeButton
    private let topBorder = SubviewsFactory.topBorder
    private let bottomBorder = SubviewsFactory.bottomBorder
    private var action: (() -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        translatesAutoresizingMaskIntoConstraints = false

        addSubviews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(icon)
        addSubview(infoLabel)
        addSubview(unsnoozeButton)
        addSubview(topBorder)
        addSubview(bottomBorder)
    }

    private func setupLayout() {
        [
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 1),
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1),
            bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor)
        ].activate()

        [
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 20),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            infoLabel.topAnchor.constraint(equalTo: topBorder.bottomAnchor, constant: 16),
            infoLabel.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor, constant: -16),
            infoLabel.trailingAnchor.constraint(equalTo: unsnoozeButton.leadingAnchor, constant: -8),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).setPriority(as: .defaultHigh),
            unsnoozeButton.heightAnchor.constraint(equalToConstant: 32),
            unsnoozeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            unsnoozeButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ].activate()
        unsnoozeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        unsnoozeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        unsnoozeButton.addTarget(
            self,
            action: #selector(self.handleAction),
            for: .touchUpInside
        )
    }

    func configure(date: String, viewMode: ViewMode, unsnoozeAction: @escaping () -> Void) {
        let infoText = String(
            format: L10n.Snooze.bannerTitle,
            date
        )
        infoLabel.set(text: infoText, preferredFont: .footnote, textColor: ColorProvider.TextNorm)
        self.action = unsnoozeAction
        if viewMode == .singleMessage {
            unsnoozeButton.removeFromSuperview()
        }
        unsnoozeButton.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
    }

    @objc
    private func handleAction() {
        action?()
    }
}

private enum SubviewsFactory {
    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: IconProvider.clock)
        imageView.tintColor = ColorProvider.NotificationWarning
        return imageView
    }

    static var infoLabel: UILabel {
        let label = UILabel()
        label.textColor = ColorProvider.TextNorm
        label.numberOfLines = 0
        return label
    }

    static var unsnoozeButton: UIButton {
        let button = UIButton(frame: .zero)
        button.titleLabel?.set(text: nil, preferredFont: .caption1)
        button.setTitle(L10n.Snooze.buttonTitle, for: .normal)
        button.backgroundColor = ColorProvider.InteractionWeak
        button.setCornerRadius(radius: 8)
        button.setTitleColor(ColorProvider.TextNorm, for: .normal)
        return button
    }

    static var topBorder: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.SeparatorNorm
        return view
    }

    static var bottomBorder: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.SeparatorNorm
        return view
    }
}
