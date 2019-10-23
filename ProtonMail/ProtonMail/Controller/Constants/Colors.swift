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
        "#7272a7", "#cf5858", "#c26cc7", "#7569d1", "#69a9d1",
        "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c",
        "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5",
        "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"
    ]
    
    static let defaultColor = ColorManager.forLabel[0]
        
    static func getRandomColor() -> String {
        return forLabel[Int.random(in: 0..<forLabel.count)]
    }
}
