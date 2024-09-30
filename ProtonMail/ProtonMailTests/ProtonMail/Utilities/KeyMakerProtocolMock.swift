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

@testable import ProtonMail
import ProtonCoreKeymaker
import ProtonCoreTestingToolkitUnitTestsCore

// auto mock
class MockKeyMakerProtocol: KeyMakerProtocol {
    var isMainKeyInMemory: Bool = false

    @PropertyStub(\MockLockCacheStatus.isPinCodeEnabled, initialGet: Bool()) var isPinCodeEnabledStub
    var isPinCodeEnabled: Bool {
        isPinCodeEnabledStub()
    }

    @PropertyStub(\MockLockCacheStatus.isTouchIDEnabled, initialGet: Bool()) var isTouchIDEnabledStub
    var isTouchIDEnabled: Bool {
        isTouchIDEnabledStub()
    }

    @PropertyStub(\MockLockCacheStatus.isAppKeyEnabled, initialGet: Bool()) var isAppKeyEnabledStub
    var isAppKeyEnabled: Bool {
        isAppKeyEnabledStub()
    }

    @PropertyStub(\MockLockCacheStatus.isAppLockedAndAppKeyEnabled, initialGet: Bool()) var isAppLockedAndAppKeyEnabledStub
    var isAppLockedAndAppKeyEnabled: Bool {
        isAppLockedAndAppKeyEnabledStub()
    }

    @FuncStub(MockKeyMakerProtocol.mainKey, initialReturn: nil) var mainKeyStub
    func mainKey(by protection: RandomPinProtection?) -> MainKey? {
        mainKeyStub(protection)
    }

    var verifyError: Error?
    func verify(protector: ProtectionStrategy) async throws {
        if let error = verifyError {
            throw error
        }
    }

    @FuncStub(MockKeyMakerProtocol.obtainMainKey) var obtainMainKeyStub
    func obtainMainKey(with protector: ProtectionStrategy, handler: @escaping (MainKey?) -> Void) {
        obtainMainKeyStub(protector, handler)
    }

    @FuncStub(MockKeyMakerProtocol.deactivate, initialReturn: Bool()) var deactivateStub
    func deactivate(_ protector: ProtectionStrategy) -> Bool {
        deactivateStub(protector)
    }

    @FuncStub(MockKeyMakerProtocol.lockTheApp) var lockTheAppStub
    func lockTheApp() {
        lockTheAppStub()
    }

    @FuncStub(MockKeyMakerProtocol.mainKeyExists, initialReturn: Bool()) var mainKeyExistsStub
    func mainKeyExists() -> Bool {
        mainKeyExistsStub()
    }

    func isProtectorActive<T: ProtectionStrategy>(_ protectionType: T.Type) -> Bool {
        return Bool()
    }

    @FuncStub(MockKeyMakerProtocol.resetAutolock) var resetAutolockStub
    func resetAutolock() {
        resetAutolockStub()
    }

    @FuncStub(MockKeyMakerProtocol.activate) var activateStub
    func activate(_ protector: ProtectionStrategy, completion: @escaping (Bool) -> Void) {
        activateStub(protector, completion)
    }

    @FuncStub(MockKeyMakerProtocol.wipeMainKey) var wipeMainKeyStub
    func wipeMainKey() {
        wipeMainKeyStub()
    }

    @FuncStub(MockKeyMakerProtocol.updateAutolockCountdownStart) var updateAutolockCountdownStartStub
    func updateAutolockCountdownStart() {
        updateAutolockCountdownStartStub()
    }
}
