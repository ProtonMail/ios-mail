//
//  DoHConstants.swift
//  ProtonCore-Doh - Created on 6/07/22.
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

public enum DoHConstants {
    public static let dohHostHeader = "x-pm-doh-host"
}

public enum ProductionHosts: String, CaseIterable {
    
    case legacyProtonMailAPI = "api.protonmail.ch"
    case legacyProtonVPNAPI = "api.protonvpn.ch"
    
    case legacyAccountApp = "account.protonmail.com"
    case legacyVerifyMailApp = "verify.protonmail.com"
    case legacyVerifyMailApi = "verify-api.protonmail.com"
    case legacyVerifyVPNApp = "verify.protonvpn.com"
    case legacyVerifyVPNApi = "verify-api.protonvpn.com"
    
    case mailAPI = "mail-api.proton.me"
    case calendarAPI = "calendar-api.proton.me"
    case driveAPI = "drive-api.proton.me"
    case vpnAPI = "vpn-api.proton.me"
    
    case accountApp = "account.proton.me"
    case accountAPI = "account-api.proton.me"
    
    case verifyApp = "verify.proton.me"
    case verifyAPI = "verify-api.proton.me"
    
    var url: URL { URL(string: "https://\(rawValue)")! }
    
    public var urlString: String { url.absoluteString }
    
    public var dohHost: String {
        let result: String
        switch self {
        case .legacyProtonMailAPI, .legacyVerifyMailApp, .legacyVerifyMailApi, .legacyAccountApp: result = "MFYGSLTQOJXXI33ONVQWS3BOMNUA"
        case .legacyProtonVPNAPI, .legacyVerifyVPNApp, .legacyVerifyVPNApi: result = "MFYGSLTQOJXXI33OOZYG4LTDNA"
        case .mailAPI: result = "NVQWS3BNMFYGSLTQOJXXI33OFZWWK"
        case .calendarAPI: result = "MNQWYZLOMRQXELLBOBUS44DSN52G63RONVSQ"
        case .driveAPI: result = "MRZGS5TFFVQXA2JOOBZG65DPNYXG2ZI"
        case .vpnAPI: result = "OZYG4LLBOBUS44DSN52G63RONVSQ"
        case .accountApp: result = "MFRWG33VNZ2C44DSN52G63RONVSQ"
        case .accountAPI: result = "MFRWG33VNZ2C2YLQNEXHA4TPORXW4LTNMU"
        case .verifyApp: result = "OZSXE2LGPEXHA4TPORXW4LTNMU"
        case .verifyAPI: result = "OZSXE2LGPEWWC4DJFZYHE33UN5XC43LF"
        }
        return "d\(result).protonpro.xyz"
    }
    
}
