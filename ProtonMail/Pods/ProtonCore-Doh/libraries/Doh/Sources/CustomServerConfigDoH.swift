//
//  CustomServerConfigDoH.swift
//  ProtonCore-Doh - Created on 16/09/2021.
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

public final class CustomServerConfigDoH: DoH, ServerConfig {
    public let signupDomain: String
    public let captchaHost: String
    public var humanVerificationV3Host: String
    public let accountHost: String
    public let defaultHost: String
    public let apiHost: String
    public let defaultPath: String
    
    public init(signupDomain: String,
                captchaHost: String,
                humanVerificationV3Host: String,
                accountHost: String,
                defaultHost: String,
                apiHost: String,
                defaultPath: String) {
        self.signupDomain = signupDomain
        self.captchaHost = captchaHost
        self.humanVerificationV3Host = humanVerificationV3Host
        self.accountHost = accountHost
        self.defaultHost = defaultHost
        self.apiHost = apiHost
        self.defaultPath = defaultPath
        super.init()
    }
    
    static var `default`: CustomServerConfigDoH!
    // swiftlint:disable function_parameter_count
    public static func build(signupDomain: String,
                             captchaHost: String,
                             humanVerificationV3Host: String,
                             accountHost: String,
                             defaultHost: String,
                             apiHost: String,
                             defaultPath: String) -> CustomServerConfigDoH {
        if CustomServerConfigDoH.default != nil && CustomServerConfigDoH.default.signupDomain == signupDomain {
            return CustomServerConfigDoH.default
        }
        return CustomServerConfigDoH.init(signupDomain: signupDomain,
                                          captchaHost: captchaHost,
                                          humanVerificationV3Host: humanVerificationV3Host,
                                          accountHost: accountHost,
                                          defaultHost: defaultHost,
                                          apiHost: apiHost, defaultPath: defaultPath)
    }
}
