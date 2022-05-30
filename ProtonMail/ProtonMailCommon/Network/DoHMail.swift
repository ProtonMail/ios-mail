//
//  DoHMail.swift
//  Created by Proton Mail on 2/24/20.
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
import ProtonCore_Doh

class DoHMail: DoH, ServerConfig {
    var apiHost: String = "dmfygsltqojxxi33onvqws3bomnua.protonpro.xyz"

    /// if set false app will ignore the Doh status settings
    var enableDoh: Bool = Constants.App.DOH_ENABLE

    var defaultHost = Constants.App.apiHost()

    var defaultPath = Constants.App.API_PATH

    var captchaHost = Constants.App.captchaHost()

    var humanVerificationV3Host = Constants.App.humanVerifyHost

    var accountHost = Constants.App.accountHost

    var signupDomain = Constants.App.domain

    var debugMode: Bool = false

    var blockList: [String: Int] = [:]

    var timeout: TimeInterval = 5

    static let `default` = DoHMail()
}
