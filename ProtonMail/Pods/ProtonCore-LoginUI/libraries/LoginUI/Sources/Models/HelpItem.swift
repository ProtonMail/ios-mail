//
//  HelpItem.swift
//  ProtonCore-Login - Created on 04/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import UIKit
import ProtonCore_CoreTranslation

enum HelpItem: CaseIterable {
    case forgotUsername
    case forgotPassword
    case otherIssues
    case support
}

extension HelpItem: CustomStringConvertible {
    var description: String {
        switch self {
        case .forgotUsername:
            return CoreString._ls_help_forgot_username
        case .forgotPassword:
            return CoreString._ls_help_forgot_password
        case .otherIssues:
            return CoreString._ls_help_other_issues
        case .support:
            return CoreString._ls_help_customer_support
        }
    }
}

extension HelpItem {
    var icon: UIImage {
        switch self {
        case .forgotUsername:
            return UIImage(named: "ForgotUsernameIcon", in: LoginAndSignup.bundle, compatibleWith: nil)!
        case .forgotPassword:
            return UIImage(named: "ForgotPasswordIcon", in: LoginAndSignup.bundle, compatibleWith: nil)!
        case .otherIssues:
            return UIImage(named: "OtherIssuesIcon", in: LoginAndSignup.bundle, compatibleWith: nil)!
        case .support:
            return UIImage(named: "SupportIcon", in: LoginAndSignup.bundle, compatibleWith: nil)!
        }
    }
}
