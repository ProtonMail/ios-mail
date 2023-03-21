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

import Foundation
import ProtonCore_UIFoundations

public enum ESBannerStyle: PMBannerStyleProtocol {
    case esBlack
    case esGray

    /// Color of banner background
    public var bannerColor: UIColor {
        switch self {
        case .esBlack:
            // BackgroundSecondary dark mode color
            return UIColor(RRGGBB: UInt(0x25272C))
        case .esGray:
            return ColorProvider.BackgroundSecondary
        }
    }

    /// Color of banner text message
    public var bannerTextColor: UIColor {
        switch self {
        case .esBlack:
            return .white
        case .esGray:
            return ColorProvider.TextWeak
        }
    }

    /// Color of assist button background
    public var assistBgColor: UIColor {
        .clear
    }

    /// Color of assist highlighted button background
    public var assistHighBgColor: UIColor {
        .clear
    }

    /// Color of assist button text
    public var assistTextColor: UIColor {
        ColorProvider.IconWeak
    }

    /// Color of banner icon
    public var bannerIconColor: UIColor {
        switch self {
        case .esBlack:
            return ColorProvider.White
        case .esGray:
            return ColorProvider.IconInverted
        }
    }

    /// Color of banner icon background
    public var bannerIconBgColor: UIColor {
        .clear
    }

    /// Lock swipe if button is shown
    public var lockSwipeWhenButton: Bool {
        return false
    }

    /// Banner border radius
    public var borderRadius: CGFloat {
        return 8
    }

    /// Banner paddings
    public var borderInsets: UIEdgeInsets {
        switch self {
        case .esBlack:
            let iconLeftPadding: CGFloat = 18
            let iconWidth: CGFloat = 20
            let textViewLeftPadding: CGFloat = 10
            let left = iconLeftPadding + iconWidth + textViewLeftPadding
            return UIEdgeInsets(top: 14, left: left, bottom: 14, right: 12)
        case .esGray:
            return UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 12)
        }
    }

    /// Message font
    public var messageFont: UIFont {
        .adjustedFont(forTextStyle: .footnote)
    }

    /// Button font
    public var buttonFont: UIFont {
        .adjustedFont(forTextStyle: .footnote)
    }

    /// Button vertical alignment
    public var buttonVAlignment: ButtonVAlignment {
        return .center
    }

    /// Button margin to the banner border
    public var buttonMargin: CGFloat {
        return 16
    }

    /// Button tittle paddings
    public var buttonInsets: UIEdgeInsets? {
        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
}

extension ESBannerStyle {

//    How to get topOffset from searchVC
//    let topOffset: CGFloat
//    let bannerPadding: CGFloat = 20
//    if #available(iOS 13, *) {
//        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
//        topOffset = statusBarHeight + navigationBarView.frame.height + bannerPadding
//    } else {
//        let statusBarHeight = UIApplication.shared.statusBarFrame.height
//        topOffset = statusBarHeight + navigationBarView.frame.height + bannerPadding
//    }

    static func showSlowSearchBanner(
        on viewController: UIViewController,
        topOffset: CGFloat,
        tapCloseButton: @escaping () -> Void,
        tapLink: @escaping () -> Void
    ) {
        let message = String(format: L11n.EncryptedSearch.slowSearchMessage, L11n.EncryptedSearch.slowSearchLink)
        guard let range = message.range(of: L11n.EncryptedSearch.slowSearchLink) else { return }
        let nsRange = NSRange(range, in: message)
        let attributed = NSMutableAttributedString(string: message, attributes: [
            .foregroundColor: ColorProvider.TextWeak as UIColor,
            .font: UIFont.adjustedFont(forTextStyle: .footnote)
        ])
        attributed.addAttributes([.link: "pm://slowsearch.exclude"], range: nsRange)
        let linkColor: UIColor = ColorProvider.BrandNorm
        let linkAttr: [NSAttributedString.Key: Any] = [.foregroundColor: linkColor]

        let banner = PMBanner(
            message: attributed,
            style: ESBannerStyle.esGray,
            dismissDuration: .infinity
        )
        banner.addButton(icon: IconProvider.crossBig) { _ in
            tapCloseButton()
        }
        banner.add(linkAttributed: linkAttr) { _, _ in
            tapLink()
        }
        banner.show(at: .topCustom(.init(top: topOffset, left: 0, bottom: 0, right: 0)), on: viewController)
    }

    static func showSearchStatusBanner(
        on viewController: UIViewController,
        topOffset: CGFloat,
        state: EncryptedSearchIndexState,
        oldestMessageInSearchIndex: String,
        tapCloseButton: @escaping () -> Void,
        tapLink: @escaping () -> Void
    ) {
        var text: String = ""
        var link: String = ""
        switch state {
        case .downloading, .refresh:
            text = L11n.EncryptedSearch.searchInfo_downloading
            link = L11n.EncryptedSearch.searchInfo_downloading_link
        case .paused(let reason):
            text = L11n.EncryptedSearch.searchInfo_paused
            link = L11n.EncryptedSearch.searchInfo_paused_link
            if let reason {
                switch reason {
                case .lowStorage:
                    text = String(format: L11n.EncryptedSearch.searchInfo_lowStorage, oldestMessageInSearchIndex)
                    link = ""
                default:
                    break
                }
            }
        case .partial:  // storage limit reached
            text = "\(L11n.EncryptedSearch.searchInfo_partial_prefix)\(oldestMessageInSearchIndex)\(L11n.EncryptedSearch.searchInfo_partial_suffix)"
            link = L11n.EncryptedSearch.searchInfo_partial_link
        case .complete,
                .undetermined,
                .background,
                .backgroundStopped,
                .disabled:
            return
        }
        let message = String(format: text, link)
        guard let range = message.range(of: link) else { return }
        let nsRange = NSRange(range, in: message)
        let attributed = NSMutableAttributedString(string: message, attributes: [
            .foregroundColor: ColorProvider.TextWeak as UIColor,
            .font: UIFont.adjustedFont(forTextStyle: .footnote)
        ])
        attributed.addAttributes([.link: "pm://search.info"], range: nsRange)
        let linkColor: UIColor = ColorProvider.BrandNorm
        let linkAttr: [NSAttributedString.Key: Any] = [.foregroundColor: linkColor]
        let banner = PMBanner(
            message: attributed,
            style: ESBannerStyle.esGray,
            dismissDuration: .infinity
        )
        banner.addButton(icon: IconProvider.crossBig) { _ in
            tapCloseButton()
        }
        banner.add(linkAttributed: linkAttr) { _, _ in
            tapLink()
        }
        banner.show(at: .topCustom(.init(top: topOffset, left: 0, bottom: 0, right: 0)), on: viewController)
    }
}
