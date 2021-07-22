//
//  Onboarding.swift
//  ProtonMail - Created on 2/24/16.
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

enum Onboarding: Int, CustomStringConvertible {
    case page1 = 0
    case page2 = 1
    case page3 = 2

    var image: UIImage? {
        switch self {
        case .page1:
            return Asset.welcome1.image
        case .page2:
            return Asset.welcome2.image
        case .page3:
            return Asset.welcome3.image
        }
    }

    var title: String {
        switch self {
        case .page1:
            return LocalString._easily_up_to_date
        case .page2:
            return LocalString._simply_private
        case .page3:
            return LocalString._neat_and_tidy
        }
    }

    var description: String {
        switch self {
        case .page1:
            return LocalString._easily_up_to_date_content
        case .page2:
            return LocalString._simply_private_content
        case .page3:
            return LocalString._neat_and_tidy_content
        }
    }
}
