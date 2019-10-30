//
//  ExternalURL.swift
//  ProtonMail
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

extension URL {
    // protonmail app store link
    static var appleStore: URL {
        return URL(string: "itms-apps://itunes.apple.com/app/id979659905")!
    }
    
    // kb for force upgrade
    static var forceUpgrade : URL {
        return URL(string: "https://protonmail.com/support/knowledge-base/update-required")!
    }
    
    // leanr more about encrypt outside - composer view
    static var eoLearnMore : URL {
        return URL(string: "https://protonmail.com/support/knowledge-base/encrypt-for-outside-users/")!
    }
    
    static var paidPlans : URL {
        return URL(string: "https://protonmail.com/support/knowledge-base/paid-plans/")!
    }
    
    static var planUpgradePage : URL {
        return URL(string: "https://protonmail.com/upgrade")!
    }
}
