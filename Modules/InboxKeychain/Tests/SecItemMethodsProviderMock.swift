//
//  KeychainMock.swift
//  ProtonCore-Keymaker-Tests - Created on 14/09/2023.
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

@testable import InboxKeychain

public final class SecItemMethodsProviderMock: SecItemMethodsProvider {
    let dataToReturn: NSData
    let resultCopyMatching: OSStatus
    let resultAdd: OSStatus
    let resultUpdate: OSStatus
    let resultDelete: OSStatus

    init(dataToReturn: NSData, resultCopyMatching: OSStatus, resultAdd: OSStatus, resultUpdate: OSStatus, resultDelete: OSStatus) {
        self.dataToReturn = dataToReturn
        self.resultCopyMatching = resultCopyMatching
        self.resultAdd = resultAdd
        self.resultUpdate = resultUpdate
        self.resultDelete = resultDelete
    }

    public func SecItemCopyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        result?.pointee = dataToReturn
        return resultCopyMatching
    }

    public func SecItemAdd(_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        return resultAdd
    }

    public func SecItemUpdate(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
        return resultUpdate
    }

    public func SecItemDelete(_ query: CFDictionary) -> OSStatus {
        return resultDelete
    }
}
