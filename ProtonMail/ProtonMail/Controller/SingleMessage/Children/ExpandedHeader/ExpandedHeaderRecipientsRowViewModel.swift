//
//  ExpandedHeaderRecipientsRowViewModel.swift
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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PMUIFoundations

struct ExpandedHeaderRecipientsRowViewModel {
    let title: NSAttributedString
    let recipients: [ExpandedHeaderRecipientRowViewModel]
}

extension ExpandedHeaderRecipientsRowViewModel {

    static var undisclosedRecipients: Self {
        .init(
            title: "\(LocalString._general_to_label):".apply(style: FontManager.body3RegularWeak),
            recipients: [
                ExpandedHeaderRecipientRowViewModel(
                    title: LocalString._undisclosed_recipients.apply(style: contactAttributes),
                    contact: nil
                )
            ]
        )
    }

    static var contactAttributes: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [
            .kern: -0.24,
            .font: font,
            .foregroundColor: UIColorManager.InteractionNorm,
            .paragraphStyle: paragraphStyle
        ]
    }

}
