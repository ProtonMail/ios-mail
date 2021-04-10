//
//  PMColors.swift
//  ProtonMail - Created on 04.11.20.
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

import Foundation

/// Colour branding
public enum Brand {
    case proton
    case vpn
}

/// Only for UIKit
public class UIColorManager {
    static public var brand: Brand = .proton
}

/// Only for SwiftUI
public enum ColorManager {
    static public var brand: Brand = .proton
}
