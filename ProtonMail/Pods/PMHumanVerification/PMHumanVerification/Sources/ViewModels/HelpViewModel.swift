//
//  HelpViewModel.swift
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

class HelpViewModel {

    // MARK: - Private properties

    private let supportURL: URL?

    // MARK: - Public properties and methods

    struct HumanItem {
        let title: String
        let subtitle: String
        let image: UIImage
        let url: URL?
    }

    var helpMenuItems: [HumanItem] {
        return HumanHelpItem.allCases.map {
            HumanItem(title: $0.title, subtitle: $0.subtitle, image: $0.image, url: ($0 == .visitHelpCenter ? supportURL : $0.url))
        }
    }

    init(url: URL?) {
        self.supportURL = url
    }
}

#endif
