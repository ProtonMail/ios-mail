//
//  CommonTests.swift
//  PMAuthenticationTests
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

import XCTest
@testable import PMAuthentication
import PMCommon

class BlackDoHMail : DoH, ServerConfig {
    var signupDomain: String = ObfuscatedConstants.blackSignupDomain
    var captchaHost: String = ObfuscatedConstants.blackCaptchaHost
    //defind your default host
    var defaultHost: String = ObfuscatedConstants.blackDefaultHost
    //defind your query host
    var apiHost : String = ObfuscatedConstants.blackApiHost
        
    var defaultPath: String = ObfuscatedConstants.blackDefaultPath
    //singleton
    static let `default` = try! BlackDoHMail()
}

class LiveDoHMail : DoH, ServerConfig {
    var signupDomain: String = "protonmail.com"
    var captchaHost: String = "https://api.protonmail.ch"
    //defind your default host
    var defaultHost: String = "https://api.protonmail.ch"
    //defind your query host
    var apiHost : String = "dmfygsltqojxxi33onvqws3bomnua.protonpro.xyz"
    //singleton
    static let `default` = try! LiveDoHMail()
}

class AnonymousServiceManager : APIServiceDelegate {
    var appVersion: String = "iOS_1.12.0"
    var userAgent: String? = nil
    func onUpdate(serverTime: Int64) { }
    func isReachable() -> Bool { return true }
    func onDohTroubleshot() { }
    func onHumanVerify() { }
    func onChallenge(challenge: URLAuthenticationChallenge, credential: AutoreleasingUnsafeMutablePointer<URLCredential?>?) -> URLSession.AuthChallengeDisposition {
        let dispositionToReturn: URLSession.AuthChallengeDisposition = .performDefaultHandling
        return dispositionToReturn
    }
}

class AnonymousAuthManager : AuthDelegate {
    var authCredential: AuthCredential?
    
    func getToken(bySessionUID uid: String) -> AuthCredential? {
        return self.authCredential
    }
    func onLogout(sessionUID uid: String) { }
    func onUpdate(auth: Credential) {
        
    }
    func onRefresh(bySessionUID uid: String, complete: (Credential?, NSError?) -> Void) {
        //defalut will be not refresh.
        complete(nil, nil)
    }
    func onForceUpgrade() { }
}
