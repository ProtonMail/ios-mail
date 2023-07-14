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
import UIKit

final class ESSpotlightView: UIView {
    private let greyOverlay = SubviewFactory.greyOverlay()
    private let greyBackgroundView = SubviewFactory.greyBackgroundView()
    private let contentView = SubviewFactory.contentView()
    private let imageView = SubviewFactory.imageView()
    private let titleLabel = SubviewFactory.titleLabel()
    private let contentLabel = SubviewFactory.contentLabel()
    private let showMeButton = SubviewFactory.showMeButton()
    private let closeButton = SubviewFactory.closeButton()
    var showMeClosure: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        layoutComponents()
        setUpActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(greyOverlay)
        addSubview(contentView)
        contentView.addSubview(greyBackgroundView)
        greyBackgroundView.addSubview(closeButton)
        greyBackgroundView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(showMeButton)
    }

    private func layoutComponents() {
        greyOverlay.fillSuperview()

        [
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).setPriority(as: .defaultLow),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).setPriority(as: .defaultLow),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 414)
        ].activate()

        [
            greyBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            greyBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            greyBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ].activate()

        [
            closeButton.leadingAnchor.constraint(equalTo: greyBackgroundView.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: greyBackgroundView.topAnchor, constant: 24),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ].activate()

        [
            imageView.topAnchor.constraint(equalTo: greyBackgroundView.topAnchor, constant: 18),
            imageView.leadingAnchor.constraint(equalTo: greyBackgroundView.leadingAnchor, constant: 118),
            imageView.trailingAnchor.constraint(equalTo: greyBackgroundView.trailingAnchor, constant: -77),
            imageView.bottomAnchor.constraint(equalTo: greyBackgroundView.bottomAnchor, constant: -25)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: greyBackgroundView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ].activate()

        [
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ].activate()

        [
            showMeButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 16),
            showMeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            showMeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            showMeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -64),
            showMeButton.heightAnchor.constraint(equalToConstant: 48)
        ].activate()

        contentView.layoutIfNeeded()
        contentView.roundCorners(at: [.topLeft, .topRight], radius: 24)
    }

    private func setUpActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        greyOverlay.addGestureRecognizer(tap)

        closeButton.addTarget(self, action: #selector(self.dismiss), for: .touchUpInside)
        showMeButton.addTarget(self, action: #selector(self.navigateToESSettingsPage), for: .touchUpInside)
    }

    @objc
    private func dismiss() {
        removeFromSuperview()
    }

    @objc
    private func navigateToESSettingsPage() {
        showMeClosure?()
        dismiss()
    }

    private enum SubviewFactory {
        static func greyOverlay() -> UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.BlenderNorm
            return view
        }

        static func greyBackgroundView() -> UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.BackgroundSecondary
            return view
        }

        static func contentView() -> UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.BackgroundNorm
            view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return view
        }

        static func imageView() -> UIImageView {
            let imageView = UIImageView(image: Asset.esIcon.image)
            imageView.contentMode = .scaleAspectFit
            return imageView
        }

        static func titleLabel() -> UILabel {
            let label = UILabel()
            label.set(
                text: L11n.EncryptedSearch.popup_title,
                preferredFont: .body,
                textColor: ColorProvider.TextNorm
            )
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            return label
        }

        static func contentLabel() -> UILabel {
            let label = UILabel()
            label.set(
                text: L11n.EncryptedSearch.popup_description,
                preferredFont: .subheadline,
                textColor: ColorProvider.TextWeak
            )
            label.textAlignment = .center
            label.numberOfLines = 0
            return label
        }

        static func showMeButton() -> UIButton {
            let button = UIButton()
            button.titleLabel?.set(text: "", preferredFont: .body)
            button.setTitle(L11n.EncryptedSearch.popup_button_title, for: .normal)
            button.setTitleColor(ColorProvider.BackgroundNorm, for: .normal)
            button.backgroundColor = ColorProvider.InteractionNorm
            button.roundCorner(8)
            return button
        }

        static func closeButton() -> UIButton {
            let button = UIButton()
            button.setImage(IconProvider.cross, for: .normal)
            button.tintColor = ColorProvider.IconNorm
            return button
        }
    }
}
