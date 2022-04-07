//
//  ProtonColorPallete+Welcome.swift
//  ProtonCore-Login - Created on 27.09.2021.
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

import ProtonCore_UIFoundations

extension ProtonColorPaletteiOS {
    
    static var White: UIColor {
        UIColor(rgb: 0xFFFFFF)
    }

    enum Welcome {
        static var Background: UIColor {
            switch Brand.currentBrand {
            case .proton:
                // Port Gore
                return UIColor(rgb: 0x1C223D)
            case .vpn:
                // Woodsmoke
                return UIColor(rgb: 0x17181C)
            }
        }
    }
}
