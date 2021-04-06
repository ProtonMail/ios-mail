//
//  AccountPlan.swift
//  PMPayments - Created on 30/11/2020.
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

public enum AccountPlan: String, CaseIterable {
    /// Commion plans
    case free = "free"
    case visionary = "visionary"
    /// mail plans
    case mailPlus = "plus"
    case pro = "professional"
    /// vpn plans
    case vpnBasic = "vpnbasic"
    case vpnPlus = "vpnplus"
    case trial = "trial"

    public var storeKitProductId: String? {
        switch self {
        case .free, .pro, .visionary, .trial: return nil
        case .mailPlus: return "ios_plus_12_usd_non_renewing"
        case .vpnBasic: return "ios_vpnbasic_12_usd_non_renewing"
        case .vpnPlus: return "ios_vpnplus_12_usd_non_renewing"
        }
    }

    public var yearlyCost: Int {
        switch self {
        case .free, .trial:
            return 0
        case .mailPlus:
            return 4800
        case .vpnBasic:
            return 4800
        case .vpnPlus:
            return 9600
        case .pro:
            return 19200 // ???
        case .visionary:
            return 28800
        }
    }

    public init(planName: String) {
        if planName == "plus" {
            self = .mailPlus
        } else if planName == "professional" {
            self = .pro
        } else if planName == "vpnbasic" {
            self = .vpnBasic
        } else if planName == "vpnplus" {
            self = .vpnPlus
        } else if planName == "visionary" {
            self = .visionary
        } else if planName == "trial" {
            self = .trial
        } else {
            self = .free
        }
    }

    internal init?(storeKitProductId: String) {
        switch storeKitProductId {
        case AccountPlan.mailPlus.storeKitProductId:
            self = .mailPlus
        case AccountPlan.vpnBasic.storeKitProductId:
            self = .vpnBasic
        case AccountPlan.vpnPlus.storeKitProductId:
            self = .vpnPlus
        default:
            return nil
        }
    }

}
