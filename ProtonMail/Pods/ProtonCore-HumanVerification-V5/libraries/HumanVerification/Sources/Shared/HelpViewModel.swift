//
//  HelpViewModel.swift
//  ProtonCore-HumanVerification - Created on 20/01/21.
//
//  Copyright (c) 2022 Proton Technologies AG
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

import enum ProtonCore_DataModel.ClientApp

public class HelpViewModel {

    // MARK: - Private properties

    private let supportURL: URL?
    private let clientApp: ClientApp

    // MARK: - Public properties and methods

    struct HumanItem {
        let title: String
        let subtitle: String
        let image: ImageType
        let url: URL?
    }

    var helpMenuItems: [HumanItem] {
        return HumanHelpItem.allCases.map {
            HumanItem(title: $0.title, subtitle: $0.subtitle, image: $0.image, url: ($0 == .visitHelpCenter ? supportURL : $0.url(clientApp: clientApp)))
        }
    }

    public init(url: URL?, clientApp: ClientApp) {
        self.supportURL = url
        self.clientApp = clientApp
    }
}
