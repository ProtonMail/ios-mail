//
//  HelpItem.swift
//  ProtonCore-Login - Created on 04/11/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import UIKit
import ProtonCoreUIFoundations

public enum HelpItem {
    case forgotUsername
    case forgotPassword
    case otherIssues
    case support
    case staticText(text: String)
    case custom(icon: UIImage, title: String, behaviour: (UIViewController) -> Void)
}

extension HelpItem: CustomStringConvertible {
    public var description: String {
        switch self {
        case .forgotUsername:
            return LUITranslation.help_forgot_username.l10n
        case .forgotPassword:
            return LUITranslation.help_forgot_password.l10n
        case .otherIssues:
            return LUITranslation.help_other_issues.l10n
        case .support:
            return LUITranslation.help_customer_support.l10n
        case .staticText(let text):
            return text
        case let .custom(_, title, _):
            return title
        }
    }
}

extension HelpItem {
    public var icon: UIImage? {
        switch self {
        case .forgotUsername:
            return IconProvider.userCircle
        case .forgotPassword:
            return IconProvider.key
        case .otherIssues:
            return IconProvider.questionCircle
        case .support:
            return IconProvider.speechBubble
        case .staticText:
            return nil
        case let .custom(icon, _, _):
            return icon
        }
    }
}

#endif
