// Copyright (c) 2023. Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

private let usersCreate = "raw::user:create"
private let usersCreateAddress = "raw::user:create:address"
private let usersExpireSessions = "raw::user:expire:sessions"
private let usersDelete = "raw::user:delete"
private let usersSubscription = "raw::user:create:subscription"

extension Quark {

    func userCreate(user: User, createAddress: CreateAddress = .withKey(genKeys: .Curve25519)) throws -> CreateUserQuarkResponse? {
        let args = [
            "-e=\(user.isExternal ? "true" : "")",
            "-em=\(user.isExternal ? user.email : "")",
            "-N=\(user.name)",
            "-p=\(user.password)",
            "-m=\(user.passphrase)",
            "-r=\(user.recoveryEmail)",
            "-c=\(createAddress == .noKey ? "true" : "")",
            "-k=\((createAddress == .withKey(genKeys: .Curve25519) ? GenKeys.Curve25519.rawValue : ""))",
            "--format=json"
        ]

        let request = try route(usersCreate)
            .args(args)
            .build()

        let (data, _) = try executeQuarkRequest(request)

        return try parseQuarkCommandJsonResponse(jsonData: data, type: CreateUserQuarkResponse.self)
    }

    func userCreateAddress(decryptedUserId: Int, password: String, email: String, genKeys: GenKeys = .Curve25519) throws -> CreateUserAddressQuarkResponse? {
        let args = [
            "userID=\(decryptedUserId)",
            "password=\(password)",
            "email=\(email)",
            "--gen-keys=\(genKeys.rawValue)",
            "--format=json"
        ]

        let request = try route(usersCreateAddress)
            .args(args)
            .build()

        let (data, _) = try executeQuarkRequest(request)

        return try parseQuarkCommandJsonResponse(jsonData: data, type: CreateUserAddressQuarkResponse.self)
    }

    func expireSession(username: String, expireRefreshToken: Bool = false) throws -> (data: Data, response: URLResponse) {
        let args = [
            "User=\(username)",
            "--refresh=\(expireRefreshToken ? "null" : "")"
        ]

        let request = try route(usersExpireSessions)
            .args(args)
            .build()

        return try executeQuarkRequest(request)
    }

    @discardableResult
    func deleteUser(id: Int) throws -> (data: Data, response: URLResponse) {
        let args = [
            "-u=\(id)",
            "-s"
        ]

        let request = try route(usersDelete)
            .args(args)
            .build()

        return try executeQuarkRequest(request)
    }

    @discardableResult
    func enableSubscription(id: Int, plan: String) throws -> (data: Data, response: URLResponse) {
        let args = [
            "userID=\(id)",
            "--planID=\(plan)"
        ]

        let request = try route(usersSubscription)
            .args(args)
            .build()

        return try executeQuarkRequest(request)
    }
}

public enum GenKeys: String {
    case Curve25519 = "Curve25519"
}

public enum CreateAddress {
    case noKey
    case withKey(genKeys: GenKeys)
}

extension CreateAddress: Equatable {
    public static func == (lhs: CreateAddress, rhs: CreateAddress) -> Bool {
        switch (lhs, rhs) {
        case (.noKey, .noKey):
            return true
        case (.withKey(let lhsGenKeys), .withKey(let rhsGenKeys)):
            return lhsGenKeys == rhsGenKeys
        default:
            return false
        }
    }
}
