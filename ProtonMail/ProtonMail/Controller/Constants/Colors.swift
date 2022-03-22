//
//  Colors.swift
//  ProtonMail - Created on 2018/8/23.
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation
import ProtonCore_UIFoundations

struct ColorManager {
    static let forLabel = [
        ColorProvider.PurpleBase.toHex(),
        ColorProvider.PinkBase.toHex(),
        ColorProvider.StrawberryBase.toHex(),
        ColorProvider.CarrotBase.toHex(),
        ColorProvider.SaharaBase.toHex(),
        ColorProvider.SlateblueBase.toHex(),
        ColorProvider.PacificBase.toHex(),
        ColorProvider.ReefBase.toHex(),
        ColorProvider.FernBase.toHex(),
        ColorProvider.OliveBase.toHex()
    ]

    static let intenseColors = [
        ColorProvider.PurpleBase.computedIntenseVariant.toHex(),
        ColorProvider.PinkBase.computedIntenseVariant.toHex(),
        ColorProvider.StrawberryBase.computedIntenseVariant.toHex(),
        ColorProvider.CarrotBase.computedIntenseVariant.toHex(),
        ColorProvider.SaharaBase.computedIntenseVariant.toHex(),
        ColorProvider.SlateblueBase.computedIntenseVariant.toHex(),
        ColorProvider.PacificBase.computedIntenseVariant.toHex(),
        ColorProvider.ReefBase.computedIntenseVariant.toHex(),
        ColorProvider.FernBase.computedIntenseVariant.toHex(),
        ColorProvider.OliveBase.computedIntenseVariant.toHex(),
    ]

    static let defaultColor = ColorManager.forLabel[0]

    static func getRandomColor() -> String {
        return forLabel[Int.random(in: 0..<forLabel.count)]
    }
}
