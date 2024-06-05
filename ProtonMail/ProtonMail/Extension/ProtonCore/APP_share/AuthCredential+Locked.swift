//
//  AuthCredential.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreNetworking

extension Locked where T == [AuthCredential] {
    internal init(clearValue: T, with key: MainKey) throws {
        let data = NSKeyedArchiver.archivedData(withRootObject: clearValue)
        let locked = try Locked<Data>(clearValue: data, with: key)
        self.init(encryptedValue: locked.encryptedValue)
    }

    internal func unlock(with key: MainKey) throws -> T {
        let locked = Locked<Data>(encryptedValue: self.encryptedValue)
        let data = try locked.unlock(with: key)
        let parsedData = try self.parse(data: data)
        return parsedData
    }

    internal func parse(data: Data) throws -> T {
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ProtonMail.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "Share.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "PushService.AuthCredential")

        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "PMCommon.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ProtonCore_Networking.AuthCredential")

        guard let value = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T else {
            throw LockedErrors.keyDoesNotMatch
        }
        return value
    }
}
