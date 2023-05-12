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
import ProtonCore_Keymaker
import ProtonCore_TestingToolkit

class MockKeyMakerProtocol: KeyMakerProtocol {
    @FuncStub(MockKeyMakerProtocol.mainKey, initialReturn: nil) var mainKeyStub
    func mainKey(by protection: RandomPinProtection?) -> MainKey? {
        mainKeyStub(protection)
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
}
