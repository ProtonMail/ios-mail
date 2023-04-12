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

final class SettingsTextFooterView: UITableViewHeaderFooterView {

    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.font = .adjustedFont(forTextStyle: .footnote)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setUpUI()
        setUpConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpUI() {
        contentView.addSubview(textView)
    }

    private func setUpConstraints() {
        [
            textView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12)
        ].activate()
        textView.centerInSuperview()
    }

    func set(text: String) {
        let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
        let attributedString = NSMutableAttributedString(string: text, attributes: attr)
        textView.attributedText = attributedString
    }

    func set(text: String, textLink: String, linkUrl: String) {
        textView.setStyledTextWithLink(text: text, textLink: textLink, linkUrl: linkUrl)
    }
}
