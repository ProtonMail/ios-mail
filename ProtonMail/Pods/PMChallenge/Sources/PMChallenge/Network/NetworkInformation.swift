//
//  NetworkInformation.swift
//  ProtonMail - Created on 6/19/20.
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

import CoreTelephony

struct NetworkInformation {
    typealias Cellular = PMChallenge.Cellular

    static func getCellularInfo() -> [PMChallenge.Cellular] {
        guard TARGET_IPHONE_SIMULATOR != 1 else {return []}

        let networkInfo = CTTelephonyNetworkInfo()

        if #available(iOS 12.0, *) {
            let carriers = networkInfo.serviceSubscriberCellularProviders?.values
            let infos = carriers?.map { Cellular(networkCode: $0.mobileNetworkCode,
                                                 countryCode: $0.mobileCountryCode) }
            return infos ?? []
        } else {
            let carrier = networkInfo.subscriberCellularProvider
            let info = PMChallenge.Cellular(networkCode: carrier?.mobileNetworkCode,
                                              countryCode: carrier?.mobileCountryCode)
            return [info]
        }
    }
}
