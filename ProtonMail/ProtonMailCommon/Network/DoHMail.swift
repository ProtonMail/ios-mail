//
//  DoHMail.swift
//  Created by ProtonMail on 2/24/20.
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
import ProtonCore_Doh

class DoHMail : DoH, ServerConfig {
    //define your signup domain
    var signupDomain: String = "protonmail.com"
    //define your default host
    var defaultHost: String = Constants.App.API_HOST_URL
    //define your host path  /api /
    var defaultPath: String = Constants.App.API_PATH
    //define your default captcha host
    var captchaHost: String = Constants.App.API_HOST_URL

    //defind your query host
    var apiHost : String = "dmfygsltqojxxi33onvqws3bomnua.protonpro.xyz"
    /// if set false app will ignore the Doh status settings
    var enableDoh: Bool = Constants.App.DOH_ENABLE
    //singleton
    static let `default` = try! DoHMail()
    
    /// debug mode
    var debugMode: Bool = false
    var blockList: [String : Int] = [:]
}
