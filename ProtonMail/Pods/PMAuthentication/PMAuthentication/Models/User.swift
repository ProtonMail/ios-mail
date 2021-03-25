//
//  User.swift
//  PMAuthentication - Created on 17/03/2020.
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

public struct User: Codable {
    public let ID: String
    public let name: String?
    public let usedSpace: Double
    public let currency: String
    public let credit: Int
    public let maxSpace: Double
    public let maxUpload: Double
    public let subscribed: Int
    public let services: Int
    public let role: Int
    public let `private`: Int
    public let delinquent: Int
    public let email: String?
    public let displayName: String?
    public let keys: [UserKey]
}

public struct UserKey: Codable {
    public let ID: String
    public let version: Int
    public let primary: Int
    public let privateKey: String
    public let fingerprint: String
}
