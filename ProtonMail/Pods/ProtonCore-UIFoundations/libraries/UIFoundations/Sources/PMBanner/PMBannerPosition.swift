//
//  PMBannerPosition.swift
//  ProtonMail - Created on 31.08.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

public enum PMBannerPosition {
    case top
    case bottom
    case topCustom(UIEdgeInsets)

    public var edgeInsets: UIEdgeInsets {
        switch self {
        case .top:
            return UIEdgeInsets(top: 8, left: 8, bottom: CGFloat.infinity, right: 8)
        case .bottom:
            return UIEdgeInsets(top: CGFloat.infinity, left: 8, bottom: 21, right: 8)
        case .topCustom(let insets):
            return insets
        }
    }

    public var maximumWidth: CGFloat {
        return 414
    }
}
