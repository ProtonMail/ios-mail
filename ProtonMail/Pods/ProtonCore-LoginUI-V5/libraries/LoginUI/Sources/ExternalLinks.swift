//
//  ExternalLinks.swift
//  ProtonCore-Login - Created on 15.12.2020.
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

import Foundation
import ProtonCore_DataModel

final class ExternalLinks {
    
    let clientApp: ClientApp
    
    init(clientApp: ClientApp) {
        self.clientApp = clientApp
    }
 
    var passwordReset: URL {
        switch clientApp {
        case .vpn:
            return URL(string: "https://account.protonvpn.com/reset-password")!
        default:
            return URL(string: "https://mail.protonmail.com/help/reset-login-password")!
        }
    }
    
    var accountSetup: URL {
        switch clientApp {
        case .vpn:
            return URL(string: "https://account.protonvpn.com/")!
        default:
            return URL(string: "https://account.protonmail.com/")!
        }
    }
    
    var termsAndConditions: URL {
        switch clientApp {
        case .vpn:
            return URL(string: "https://protonvpn.com/ios-terms-and-conditions.html")!
        default:
            return URL(string: "https://protonmail.com/ios-terms-and-conditions.html")!
        }
    }
    
    var support: URL {
        switch clientApp {
        case .vpn:
            return URL(string: "https://protonvpn.com/support")!
        default:
            return URL(string: "https://protonmail.com/support-form")!
        }
    }
    
    var commonLoginProblems: URL {
        switch clientApp {
        case .vpn:
            return URL(string: "https://protonvpn.com/support/login-problems")!
        default:
            return URL(string: "https://protonmail.com/support/knowledge-base/common-login-problems")!
        }
    }
    
    var forgottenUsername: URL {
        switch clientApp {
        case .vpn:
            return URL(string: "https://account.protonvpn.com/forgot-username")!
        default:
            return URL(string: "https://protonmail.com/username")!
        }
    }
}
