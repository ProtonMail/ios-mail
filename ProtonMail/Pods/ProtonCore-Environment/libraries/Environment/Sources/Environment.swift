//
//  Environment.swift
//  ProtonCore-Doh - Created on 24/03/22.
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
import ProtonCore_Doh
import TrustKit

public enum Environment {
    case mailProd
    case vpnProd
    case driveProd
    case calendarProd
    case black
    case blackPayment
    
    case custom(String)
    
    static let productionMail = ProductionMail()
    static let productionVPN = ProductionVPN()
    static let productionDrive = ProductionDrive()
    static let productionCalendar = ProductionCalendar()
    static let blackServer = Environment.buildCustomDoh(customDomain: "proton.black")
    static let blackPaymentsServer = Environment.buildCustomDoh(customDomain: "payments.proton.black")
}

extension Environment {
    public static var prebuild: [Environment] = [.mailProd, .vpnProd, .driveProd, .calendarProd, .black, .blackPayment]
}

extension Environment: Equatable {
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
        switch (lhs, rhs) {
        case (.mailProd, .mailProd), (.vpnProd, .vpnProd), (.driveProd, .driveProd), (.calendarProd, .calendarProd),
            (.black, .black), (.blackPayment, .blackPayment):
            return true
        case (.custom(let lvalue), .custom(let rvalue)):
            return lvalue == rvalue
        default:
            return false
        }
    }
}

extension Environment {
    static var supported: [Environment] = [.black]
    public static func setup(scopes: [Environment]) -> Void {
        supported = scopes
    }
    
    public func updateDohStatus(to status: DoHStatus) {
        switch self {
        case .mailProd:
            Environment.productionMail.status = status
        case .vpnProd:
            Environment.productionVPN.status = status
        case .driveProd:
            Environment.productionDrive.status = status
        case .calendarProd:
            Environment.productionCalendar.status = status
        case .black:
            Environment.blackServer.status = status
        case .blackPayment:
            Environment.blackPaymentsServer.status = status
        case .custom:
            assertionFailure("Cannot set doH status of custom black environment via this method")
        }
    }
        
    public var doh: DoH & ServerConfig {
        switch self {
        case .mailProd:
            return Environment.productionMail
        case .vpnProd:
            return Environment.productionVPN
        case .driveProd:
            return Environment.productionDrive
        case .calendarProd:
            return Environment.productionCalendar
        case .black:
            return Environment.blackServer
        case .blackPayment:
            return Environment.blackPaymentsServer
        case .custom(let customDomain):
            return Environment.buildCustomDoh(customDomain: customDomain)
        }
    }
    
    public var dohModifiable: DoH & VerificationModifiable {
        switch self {
        case .mailProd:
            return Environment.productionMail
        case .vpnProd:
            return Environment.productionVPN
        case .driveProd:
            return Environment.productionDrive
        case .calendarProd:
            return Environment.productionCalendar
        case .black, .blackPayment, .custom:
            fatalError("Invalid index")
        }
    }
    
    static func buildCustomDoh(customDomain: String) -> CustomServerConfigDoH {
        return CustomServerConfigDoH.build(
            signupDomain: customDomain,
            captchaHost: "https://api.\(customDomain)",
            humanVerificationV3Host: "https://verify.\(customDomain)",
            accountHost: "https://account.\(customDomain)",
            defaultHost: "https://\(customDomain)",
            apiHost: ProductionHosts.legacyProtonMailAPI.dohHost,
            defaultPath: "/api"
        )
    }
}

extension Environment {
    public static func setUpTrustKit(delegate: TrustKitDelegate, customConfiguration: Configuration? = nil) -> TrustKit? {
        TrustKitWrapper.setUp(delegate: delegate, customConfiguration: customConfiguration)
        return TrustKitWrapper.current
    }
    
    public static var trustKit: TrustKit? {
        TrustKitWrapper.current
    }
    
    public static func pinningConfigs(hardfail: Bool) -> Configuration {
        return TrustKitWrapper.configuration(hardfail: hardfail)
    }
}
