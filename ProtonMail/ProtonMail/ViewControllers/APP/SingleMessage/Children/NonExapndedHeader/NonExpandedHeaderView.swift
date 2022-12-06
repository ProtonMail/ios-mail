//
//  NonExpandedHeaderView.swift
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

class NonExpandedHeaderView: UIView {

    let initialsContainer = SubviewsFactory.container
    let initialsLabel = UILabel.initialsLabel
    let senderLabel = SubviewsFactory.senderLabel
    let senderAddressLabel = TextControl()
    let lockImageView = SubviewsFactory.lockImageView
    let lockImageControl = UIControl(frame: .zero)
    let originImageView = SubviewsFactory.originImageView
    lazy var originImageContainer = StackViewContainer(view: originImageView)
    let sentImageView = SubviewsFactory.sentImageView
    lazy var sentImageContainer = StackViewContainer(view: sentImageView)
    let timeLabel = SubviewsFactory.timeLabel
    let contentStackView = UIStackView.stackView(axis: .vertical, spacing: 8)
    let recipientTitle = SubviewsFactory.recipientTitle
    let recipientLabel = SubviewsFactory.recipientLabel
    let tagsView = SingleRowTagsView()
    let trackerProtectionImageView = SubviewsFactory.trackerProtectionImageView
    let starImageView = SubviewsFactory.starImageView
    private(set) lazy var lockContainer = StackViewContainer(view: lockImageControl, top: 4)

    var expandView: (() -> Void)?

    private let firstLineStackView = UIStackView.stackView(
        axis: .horizontal,
        distribution: .fill,
        alignment: .center,
        spacing: 5
    )
    private let senderAddressStack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)
    private let recipientStack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
        setUpGestures()
    }

    func showTrackerDetectionStatus(_ status: NonExpandedHeaderViewModel.TrackerDetectionStatus) {
        let icon: UIImage?
        let tintColor: UIColor?
        switch status {
        case .trackersFound:
            icon = IconProvider.shieldFilled
            tintColor = ColorProvider.IconAccent
        case .noTrackersFound, .notDetermined:
            icon = IconProvider.shield
            tintColor = ColorProvider.IconWeak
        case .proxyNotEnabled:
            icon = nil
            tintColor = nil
        }
        trackerProtectionImageView.image = icon
        trackerProtectionImageView.isHidden = icon == nil
        trackerProtectionImageView.tintColor = tintColor
    }

    private func addSubviews() {
        addSubview(initialsContainer)
        addSubview(contentStackView)

        initialsContainer.addSubview(initialsLabel)
        lockImageControl.addSubview(lockImageView)

        contentStackView.addArrangedSubview(firstLineStackView)
        contentStackView.setCustomSpacing(4, after: firstLineStackView)

        firstLineStackView.addArrangedSubview(senderLabel)
        firstLineStackView.addArrangedSubview(UIView())
        firstLineStackView.addArrangedSubview(starImageView)
        firstLineStackView.addArrangedSubview(trackerProtectionImageView)
        firstLineStackView.addArrangedSubview(sentImageContainer)
        firstLineStackView.addArrangedSubview(originImageContainer)
        firstLineStackView.addArrangedSubview(timeLabel)

        contentStackView.addArrangedSubview(senderAddressStack)
        contentStackView.setCustomSpacing(4, after: senderAddressStack)
        senderAddressStack.addArrangedSubview(lockContainer)
        senderAddressStack.addArrangedSubview(senderAddressLabel)
        senderAddressStack.addArrangedSubview(UIView(frame: .zero))
        senderAddressStack.setCustomSpacing(4, after: lockContainer)
        // 32 reply button + 8 * 2 spacing + 32 more button
        senderAddressStack.setCustomSpacing(80, after: senderAddressLabel)

        recipientStack.addArrangedSubview(recipientTitle)
        recipientStack.addArrangedSubview(recipientLabel)
        recipientStack.setCustomSpacing(80, after: recipientLabel)
        recipientStack.addArrangedSubview(UIView())
        contentStackView.addArrangedSubview(recipientStack)
        contentStackView.setCustomSpacing(4, after: recipientStack)
        contentStackView.addArrangedSubview(tagsView)
    }

    private func setUpLayout() {
        let square16x16Views: [UIView] = [
            lockContainer,
            originImageView,
            sentImageView,
            starImageView,
            trackerProtectionImageView
        ]
        for view in square16x16Views {
            [
                view.heightAnchor.constraint(equalToConstant: 16),
                view.widthAnchor.constraint(equalToConstant: 16)
            ].activate()
        }

        [
            initialsContainer.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            initialsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            initialsContainer.trailingAnchor.constraint(equalTo: firstLineStackView.leadingAnchor, constant: -10),
            initialsContainer.heightAnchor.constraint(equalToConstant: 28),
            initialsContainer.widthAnchor.constraint(equalToConstant: 28)
        ].activate()

        [
            initialsLabel.centerYAnchor.constraint(equalTo: initialsContainer.centerYAnchor),
            initialsLabel.leadingAnchor.constraint(equalTo: initialsContainer.leadingAnchor, constant: 2),
            initialsLabel.trailingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: -2)
        ].activate()

        [
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            // 56 = 20 (1st line) + 16 (2st) + 20 (3st)
            contentStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ].activate()

        lockImageView.fillSuperview()

        // The reason to set height anchor is to fix UI
        // Without these constraints the sender name position will change between
        // non-expanded and expanded
        // When font large enough
        [
            senderLabel.heightAnchor.constraint(equalToConstant: 20)
        ].activate()

        [
            recipientTitle.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ].activate()

        [
            senderLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ].activate()
        senderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        senderLabel.setContentHuggingPriority(.required, for: .vertical)

        timeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        timeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private func setUpGestures() {
        isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(expandTapped))
        addGestureRecognizer(tapGR)
    }

    @objc
    private func expandTapped() {
        expandView?()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var originImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconWeak
        return imageView
    }

    static var sentImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = IconProvider.paperPlane
        imageView.tintColor = ColorProvider.IconWeak
        return imageView
    }

    static var container: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.InteractionWeak
        view.layer.cornerRadius = 8
        view.isUserInteractionEnabled = false
        return view
    }

    static var starImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = IconProvider.starFilled
        imageView.tintColor = ColorProvider.NotificationWarning
        return imageView
    }

    static var lockImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    static var timeLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .right
        label.set(text: nil,
                  preferredFont: .footnote,
                  textColor: ColorProvider.TextWeak)
        return label
    }

    static var senderLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.set(text: nil, preferredFont: .subheadline)
        return label
    }

    static var recipientTitle: UILabel {
        let label = UILabel(frame: .zero)
        label.set(text: "\(LocalString._general_to_label): ", preferredFont: .footnote)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    static var recipientLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.set(text: nil,
                  preferredFont: .footnote,
                  textColor: ColorProvider.TextWeak)
        return label
    }

    static var trackerProtectionImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }
}
