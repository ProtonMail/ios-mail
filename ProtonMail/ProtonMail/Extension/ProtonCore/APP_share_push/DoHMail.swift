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
    let enableDoh = Constants.App.DOH_ENABLE

    let defaultHost = Constants.App.apiHost()

    let defaultPath = Constants.App.API_PATH

    let captchaHost = Constants.App.captchaHost()

    let humanVerificationV3Host = Constants.App.humanVerifyHost

    let accountHost = Constants.App.accountHost

    let signupDomain = Constants.App.appDomain

    let debugMode = false

    let timeout: TimeInterval = 5

    static let `default` = DoHMail()
}
