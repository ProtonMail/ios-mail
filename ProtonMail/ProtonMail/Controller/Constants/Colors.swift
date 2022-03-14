//
//  Colors.swift
//  ProtonMail - Created on 2018/8/23.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation

struct ColorManager {
    static let forLabel = [
        "#7272a7", "#8989ac", "#cf5858", "#cf7e7e",
        "#c26cc7", "#c793ca", "#7569d1", "#9b94d1",
        "#69a9d1", "#a8c4d5", "#5ec7b7", "#97c9c1",
        "#72bb75", "#9db99f", "#c3d261", "#c6cd97",
        "#e6c04c", "#e7d292", "#e6984c", "#dfb286"
    ]

    static let defaultColor = ColorManager.forLabel[0]

    static func getRandomColor() -> String {
        return forLabel[Int.random(in: 0..<forLabel.count)]
    }
}
