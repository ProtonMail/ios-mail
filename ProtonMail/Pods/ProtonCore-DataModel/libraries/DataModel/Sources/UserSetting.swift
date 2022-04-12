//
//  User.swift
//  ProtonCore-DataModel - Created on 17/03/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

struct NotifySetting {
    // "Value": "abc@gmail.com",
    public let value: String
    // "Status": 0,
    public let status: Int
    // "Notify": 1,
    public let notify: Int
    // "Reset": 0
    public let reset: Int
}

struct PasswordSetting {
    public let mode: Int
    public let expirationTime: String
}

struct U2FKey {
    // "Label": "A name",
    let label: String
    // "KeyHandle": "aKeyHandle",
    let keyHandle: String
    // "Compromised": 0
    let compromised: Int
}

struct TFASetting {
    // "Enabled": 3,
    let  enabled: Int
    // "Allowed": 3,
    let allowed: Int
    // "ExpirationTime": null,
    let expirationTime: String
    // "U2FKeys": [U2FKey]
    let u2fKeys: [U2FKey]
}

public struct UserSetting {
    let email: NotifySetting
    let phone: NotifySetting
    let password: PasswordSetting
    let twoFA: TFASetting
    
    // "News": 244,
    let news: Int
    // "Locale": "en_US",
    let locale: String
    // "LogAuth": 2,
    let logAuth: Int
    // "InvoiceText": "hblahlblahblah",
    let invoiceText: String
    // "Density": 0,
    let  density: Int
    // "Theme": "css",
    let theme: String
    // "ThemeType": 1,
    let themeType: Int
    // "WeekStart": 1,
    let weekStart: Int
    // "DateFormat": 1,
    let dateFormat: Int
    // "TimeFormat": 1,
    let timeFormat: Int
    // "WelcomeFlag": "1"
    let welcomeFlag: Int
}
