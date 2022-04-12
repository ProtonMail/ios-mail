//
//  ConversationViewTrashedHintCell.swift
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

import UIKit

protocol ConversationViewTrashedHintDelegate: AnyObject {
    func clickTrashedMessageSettingButton()
}

class ConversationViewTrashedHintCell: UITableViewCell {
    private let customView = ConversationViewTrashedHintView()
    private weak var delegate: ConversationViewTrashedHintDelegate?
    
    required init?(coder: NSCoder) {
        nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setUpSubviews()
        setUpLayout()
    }
    
    /// Is trashed message hidden
    func setup(isTrashFolder: Bool,
               useShowButton: Bool,
               delegate: ConversationViewTrashedHintDelegate?) {
        self.delegate = delegate
        customView.setup(isTrashFolder: isTrashFolder, useShowButton: useShowButton)
    }

    private func setUpSubviews() {
        contentView.addSubview(customView)
        customView.button.addTarget(self,
                                    action: #selector(self.clickButton),
                                    for: .touchUpInside)
    }
    
    private func setUpLayout() {
        [
            customView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            customView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            customView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            customView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ].activate()
    }

    @objc private func clickButton() {
        self.delegate?.clickTrashedMessageSettingButton()
    }
}
