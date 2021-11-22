//
//  NewMailboxMessageCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import SwipyCell
import UIKit

protocol NewMailboxMessageCellDelegate: AnyObject {
    func didSelectButtonStatusChange(id: String?)
    func getExpirationDate(id: String) -> String?
}

class NewMailboxMessageCell: SwipyCell, AccessibleCell {

    weak var cellDelegate: NewMailboxMessageCellDelegate?
    private var shouldUpdateTime: Bool = false
    var id: String?
    private var workItem: DispatchWorkItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setUpLayout()
        setUpAvatarTapHandling()
        generateCellAccessibilityIdentifiers("mailboxMessageCell")
    }

    let customView = NewMailboxMessageCellContentView()

    override func prepareForReuse() {
        super.prepareForReuse()

        shouldUpdateTime = false
        workItem?.cancel()
        workItem = nil

        customView.initialsLabel.attributedText = nil
        customView.initialsLabel.isHidden = false
        customView.checkBoxView.isHidden = true
        customView.messageContentView.tagsView.tagViews = []
        customView.messageContentView.removeTagsView()
        customView.messageContentView.forwardImageView.isHidden = false
        customView.messageContentView.tintColor = ColorProvider.IconWeak
        customView.messageContentView.replyImageView.isHidden = false
        customView.messageContentView.replyImageView.tintColor = ColorProvider.IconWeak
        customView.messageContentView.replyAllImageView.isHidden = false
        customView.messageContentView.replyAllImageView.tintColor = ColorProvider.IconWeak
        customView.messageContentView.senderLabel.attributedText = nil
        customView.messageContentView.timeLabel.attributedText = nil
        customView.messageContentView.attachmentImageView.isHidden = false
        customView.messageContentView.starImageView.isHidden = false
        customView.messageContentView.titleLabel.attributedText = nil
        customView.messageContentView.draftImageView.isHidden = false
        customView.messageContentView.removeOriginImages()
        customView.messageContentView.messageCountLabel.isHidden = false
    }

    func startUpdateExpiration() {
        shouldUpdateTime = true
        getExpirationOffset()
    }

    private func getExpirationOffset() {
        let workItem = DispatchWorkItem { [weak self] in
            if self?.shouldUpdateTime == true,
               let id = self?.id,
               let expiration = self?.cellDelegate?.getExpirationDate(id: id) {
                let tag = self?.customView.messageContentView.tagsView.tagViews.compactMap({ $0 as? TagIconView })
                    .first(where: { $0.imageView.image == Asset.mailHourglass.image })
                tag?.tagLabel.attributedText = expiration.apply(style: FontManager.OverlineRegularInteractionStrong)
                self?.getExpirationOffset()
            } else {
                self?.shouldUpdateTime = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: workItem)
        self.workItem = workItem
    }

    private func addSubviews() {
        contentView.addSubview(customView)
    }

    private func setUpLayout() {
        customView.translatesAutoresizingMaskIntoConstraints = false
        [
            customView.topAnchor.constraint(equalTo: contentView.topAnchor),
            customView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
            .activate()
    }

    private func setUpAvatarTapHandling() {
        customView.leftContainer.addTarget(self, action: #selector(avatarTapped(_:)), for: .touchUpInside)
    }

    @objc
    private func avatarTapped(_ sender: UIControl) {
        cellDelegate?.didSelectButtonStatusChange(id: id)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let point = gesture.location(in: self)
        guard point.x > 55 else {
            // Ignore gesture for showing the menu
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
