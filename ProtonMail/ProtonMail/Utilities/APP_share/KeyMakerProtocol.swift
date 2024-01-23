// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreKeymaker

protocol KeyMakerProtocol: AnyObject, LockCacheStatus {
    var isMainKeyInMemory: Bool { get }

    func mainKey(by protection: RandomPinProtection?) -> MainKey?
    func obtainMainKey(
        with protector: ProtectionStrategy,
        handler: @escaping (MainKey?) -> Void
    )
    func verify(protector: ProtectionStrategy) async throws
    @discardableResult
    func deactivate(_ protector: ProtectionStrategy) -> Bool
    func lockTheApp()
    func mainKeyExists() -> Bool
    func isProtectorActive<T: ProtectionStrategy>(_ protectionType: T.Type) -> Bool
    func resetAutolock()
    func activate(_ protector: ProtectionStrategy, completion: @escaping (Bool) -> Void)
    func wipeMainKey()
    func updateAutolockCountdownStart()
}

extension Keymaker: KeyMakerProtocol {}
