//
//  HumanHelpItem.swift
//  ProtonMail - Created on 20/01/21.
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

#if canImport(UIKit)
import UIKit
import ProtonCore_CoreTranslation

enum HumanHelpItem: CaseIterable {
    case requestInvite
    case visitHelpCenter
}

extension HumanHelpItem {
    var title: String {
        switch self {
        case .requestInvite:
            return CoreString._hv_help_request_item_title
        case .visitHelpCenter:
            return CoreString._hv_help_visit_item_title
        }
    }

    var subtitle: String {
        switch self {
        case .requestInvite:
            return CoreString._hv_help_request_item_message
        case .visitHelpCenter:
            return CoreString._hv_help_visit_item_message
        }
    }

    var image: UIImage {
        switch self {
        case .requestInvite:
            return UIImage(named: "ic-check-circle", in: HVCommon.bundle, compatibleWith: nil)!
        case .visitHelpCenter:
            return UIImage(named: "ic-lightbulp", in: HVCommon.bundle, compatibleWith: nil)!
        }
    }

    var url: URL? {
        switch self {
        case .requestInvite:
            return URL(string: "https://protonmail.com/support-form")
        case .visitHelpCenter:
            return nil
        }
    }
}
#endif
