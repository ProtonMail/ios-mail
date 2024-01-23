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

final class AttachmentPreviewView: UIView {
    private let attachmentPreview: AttachmentPreviewViewModel
    private let iconImageView = UIImageView()
    private let filenameLabel = UILabel()

    var attachmentSelected: (() -> Void)?

    init(attachmentPreview: AttachmentPreviewViewModel) {
        self.attachmentPreview = attachmentPreview
        super.init(frame: .zero)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true

        configureBorder()
        configureViews()
        addConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(attachmentPreview: AttachmentPreview) please")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = ColorProvider.InteractionWeak
        }
    }

    private func configureBorder() {
        layer.borderColor = ColorProvider.SeparatorNorm
        layer.borderWidth = 1
        roundCorner(6)
    }

    private func configureViews() {
        addSubviews(iconImageView, filenameLabel)
        backgroundColor = ColorProvider.BackgroundNorm
        iconImageView.image = attachmentPreview.icon
        let style = FontManager.Caption.foregroundColor(ColorProvider.TextNorm)
        filenameLabel.attributedText = attachmentPreview.name.apply(style: style)
        filenameLabel.lineBreakMode = .byTruncatingMiddle
    }

    private func addConstraints() {
        [
            heightAnchor.constraint(equalToConstant: 28),
            centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor, multiplier: 1.0),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            filenameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            filenameLabel.bottomAnchor.constraint(equalTo: iconImageView.bottomAnchor),
            filenameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ].activate()
    }

    @objc
    private func handleTap() {
        self.isUserInteractionEnabled = false
        attachmentSelected?()
        UIView.animate(withDuration: 0.15) {
            self.backgroundColor = ColorProvider.BackgroundSecondary
        } completion: { _ in
            UIView.animate(withDuration: 0.15) {
                self.backgroundColor = ColorProvider.BackgroundNorm
            }
            completion: { _ in
                self.isUserInteractionEnabled = true
            }
        }
    }
}
