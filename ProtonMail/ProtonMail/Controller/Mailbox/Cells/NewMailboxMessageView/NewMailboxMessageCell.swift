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

import PMUIFoundations
import SwipyCell
import UIKit

protocol NewMailboxMessageCellDelegate: class {
    func didSelectButtonStatusChange(id: String?)
}

class NewMailboxMessageCell: SwipyCell {

    weak var cellDelegate: NewMailboxMessageCellDelegate?
    var id: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setUpLayout()
        setUpAvatarTapHandling()
    }

    let customView = NewMailboxMessageCellContentView()

    override func prepareForReuse() {
        super.prepareForReuse()

        customView.initialsLabel.attributedText = nil
        customView.initialsLabel.isHidden = false
        customView.checkBoxView.isHidden = true
        customView.messageContentView.tagsView.tagViews = []
        customView.messageContentView.removeTagsView()
        customView.messageContentView.forwardImageView.isHidden = false
        customView.messageContentView.tintColor = UIColorManager.IconWeak
        customView.messageContentView.replyImageView.isHidden = false
        customView.messageContentView.replyImageView.tintColor = UIColorManager.IconWeak
        customView.messageContentView.replyAllImageView.isHidden = false
        customView.messageContentView.replyAllImageView.tintColor = UIColorManager.IconWeak
        customView.messageContentView.senderLabel.attributedText = nil
        customView.messageContentView.timeLabel.attributedText = nil
        customView.messageContentView.attachmentImageView.isHidden = false
        customView.messageContentView.starImageView.isHidden = false
        customView.messageContentView.titleLabel.attributedText = nil
        customView.messageContentView.draftImageView.isHidden = false
        customView.messageContentView.originImageView.isHidden = false
        customView.messageContentView.originImageView.image = nil
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

}
