//
//  BannerViewModel.swift
//  ProtonMail
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

enum SpamType {
    case dmarcFailed
    case autoPhishing
}

extension SpamType {

    var text: NSAttributedString {
        switch self {
        case .autoPhishing:
            return LocalString._auto_phising_banner_message.apply(style: FontManager.CaptionInverted)
        case .dmarcFailed:
            let message = LocalString._dmarc_failed_banner_message.apply(style: FontManager.CaptionInverted)
            let learnMore = LocalString._learn_more.apply(style: linkAttributes)
            return message + .init(string: " ") + learnMore
        }
    }

    var icon: UIImage {
        switch self {
        case .autoPhishing:
            return IconProvider.hook
        case .dmarcFailed:
            return IconProvider.fire
        }
    }

    var buttonTitle: NSAttributedString? {
        guard case .autoPhishing = self else { return nil }
        return LocalString._auto_phising_banner_button_title.apply(style: FontManager.body2RegularInverted)
    }

    private var linkAttributes: [NSAttributedString.Key: Any] {
        FontManager.CaptionInverted + [
            .link: Link.dmarcFailedInfo,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: ColorProvider.TextInverted
        ]
    }

}
