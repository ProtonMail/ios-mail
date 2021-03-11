//
//  CommonTests.swift
//  PMAuthenticationTests
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

struct TestUser {
    let username: String
    let password: String
}

extension TestUser {
    static let liveTestUser = TestUser(username: ObfuscatedConstants.liveTestUserUsername, password: ObfuscatedConstants.liveTestUserPassword)
    static let liveTest2FAUser = TestUser(username: ObfuscatedConstants.liveTest2FAUserUsername, password: ObfuscatedConstants.liveTest2FAUserPassword)
    static let blueDriveTestUser = TestUser(username: ObfuscatedConstants.blueDriveUserUsername, password: ObfuscatedConstants.blueDriveUserPassword)
    static let externalTestUser = TestUser(username: ObfuscatedConstants.externalUserUsername, password: ObfuscatedConstants.externalUserPassword)
}
