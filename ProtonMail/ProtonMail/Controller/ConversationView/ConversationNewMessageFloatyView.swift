//
//  ConversationNewMessageFloatyView.swift
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

class ConversationNewMessageFloatyView: UIView {

    let titleLabel = UILabel(frame: .zero)
    var handleTapAction: (() -> Void)?
    private let didHide: () -> Void
    private let button = UIButton(frame: .zero)
    private var timer: Timer?

    init(didHide: @escaping () -> Void) {
        self.didHide = didHide
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()

        button.backgroundColor = .clear
        button.setTitle(nil, for: .normal)

        button.addTarget(self, action: #selector(self.handleTap), for: .touchUpInside)

        let attribute = FontManager
            .CaptionStrongInverted
            .alignment(.center)
            .addTruncatingTail()
        titleLabel.attributedText = LocalString._conversation_new_message_button.apply(style: attribute)

        backgroundColor = ColorProvider.BrandNorm
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        addSubview(titleLabel)
        addSubview(button)
    }

    private func setUpLayout() {
        [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36)
        ].activate()
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        button.fillSuperview()
        layer.cornerRadius = 24
    }

    @objc
    private func handleTap() {
        timer?.invalidate()
        handleTapAction?()
        removeFromSuperview()
        didHide()
    }

    func handleTapAction(action: (() -> Void)?) {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
            self?.removeFromSuperview()
            self?.didHide()
        })
        self.handleTapAction = action
    }
}
