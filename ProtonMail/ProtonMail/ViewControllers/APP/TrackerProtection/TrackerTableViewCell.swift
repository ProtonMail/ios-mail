// Copyright (c) 2022 Proton AG
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

class TrackerTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }

    private let contentTextView = SubviewFactory.contentTextView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        addSubviews()
        setUpConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with url: UnsafeRemoteURL) {
        contentTextView.attributedText = url.value.apply(style: FontManager.DefaultWeak)
        contentTextView.font = .adjustedFont(forTextStyle: .body)
    }

    private func addSubviews() {
        contentView.addSubview(contentTextView)
    }

    private func setUpConstraints() {
        contentTextView.centerXInSuperview()
        NSLayoutConstraint.activate([
            contentTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            contentTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            contentTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
        ])
    }
}

private enum SubviewFactory {
    static var contentTextView: UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textColor = ColorProvider.TextHint
        return textView
    }
}
