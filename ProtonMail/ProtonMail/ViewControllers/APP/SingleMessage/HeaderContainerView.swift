//
//  HeaderContainerView.swift
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

class HeaderContainerView: UIView {
    enum ReplyState {
        static func from(moreThanOneContact: Bool, isScheduled: Bool) -> Self {
            if isScheduled {
                return .none
            } else if moreThanOneContact {
                return .replyAll
            } else {
                return .reply
            }
        }

        case reply
        case replyAll
        case none

        var buttonAccessibilityLabel: String? {
            switch self {
            case .reply:
                return LocalString._general_reply_button
            case .replyAll:
                return LocalString._general_replyall_button
            case .none:
                return nil
            }
        }

        var imageView: UIImageView? {
            switch self {
            case .reply:
                return SubviewsFactory.replyImageView
            case .replyAll:
                return SubviewsFactory.replyAllImageView
            case .none:
                return nil
            }
        }
    }

    init(replyState: ReplyState) {
        self.replyState = replyState
        self.replyImageView = replyState.imageView
        super.init(frame: .zero)
        setUp()
        addSubviews()
        setUpLayout()
    }

    let replyState: ReplyState
    let replyControl = UIControl(frame: .zero)
    let moreControl = UIControl(frame: .zero)
    let contentContainer = UIView(frame: .zero)
    private let moreImageView = SubviewsFactory.moreImageView
    private let replyImageView: UIImageView?

    private func setUp() {
        replyControl.isAccessibilityElement = true
        replyControl.accessibilityTraits = .button
        replyControl.accessibilityLabel = replyState.buttonAccessibilityLabel

        moreControl.isAccessibilityElement = true
        moreControl.accessibilityTraits = .button
        moreControl.accessibilityLabel = LocalString._general_more

        accessibilityElements = [replyControl, moreControl, contentContainer]
    }

    private func addSubviews() {
        addSubview(contentContainer)
        addSubview(replyControl)
        addSubview(moreControl)
        if let imageView = replyImageView {
            replyControl.addSubview(imageView)
        } else {
            moreControl.isHidden = true
            replyControl.isHidden = true
        }
        moreControl.addSubview(moreImageView)
        replyControl.layer.borderWidth = 1
        replyControl.layer.borderColor = ColorProvider.SeparatorNorm.cgColor
        replyControl.setCornerRadius(radius: 8)
        moreControl.layer.borderWidth = 1
        moreControl.layer.borderColor = ColorProvider.SeparatorNorm.cgColor
        moreControl.setCornerRadius(radius: 8)
    }

    private func setUpLayout() {
        [
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()

        [contentContainer.widthAnchor.constraint(equalTo: widthAnchor)].activate()

        [
            replyControl.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            replyControl.trailingAnchor.constraint(equalTo: moreControl.leadingAnchor, constant: -8),
            replyControl.widthAnchor.constraint(equalToConstant: 32),
            replyControl.heightAnchor.constraint(equalToConstant: 32),
            replyControl.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ].activate()

        [
            moreControl.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            moreControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            moreControl.widthAnchor.constraint(equalToConstant: 32),
            moreControl.heightAnchor.constraint(equalToConstant: 32),
            moreControl.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ].activate()

        if let imageView = replyImageView {
            [
                imageView.centerXAnchor.constraint(equalTo: replyControl.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: replyControl.centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 16),
                imageView.widthAnchor.constraint(equalToConstant: 16)
            ].activate()
        }

        [
            moreImageView.centerXAnchor.constraint(equalTo: moreControl.centerXAnchor),
            moreImageView.centerYAnchor.constraint(equalTo: moreControl.centerYAnchor),
            moreImageView.heightAnchor.constraint(equalToConstant: 16),
            moreImageView.widthAnchor.constraint(equalToConstant: 16)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {
    static var moreImageView: UIImageView {
        let imageView = UIImageView()
        imageView.image = IconProvider.threeDotsHorizontal
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }

    static var replyImageView: UIImageView {
        let imageView = UIImageView()
        imageView.image = IconProvider.arrowUpAndLeft
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }

    static var replyAllImageView: UIImageView {
        let imageView = UIImageView()
        imageView.image = IconProvider.arrowsUpAndLeft
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }
}
