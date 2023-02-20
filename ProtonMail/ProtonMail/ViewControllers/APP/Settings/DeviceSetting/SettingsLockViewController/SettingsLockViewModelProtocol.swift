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

import Foundation

protocol SettingsLockViewModelProtocol: AnyObject {
    var input: SettingsLockViewModelInput { get }
    var output: SettingsLockViewModelOutput { get }
}

protocol SettingsLockViewModelInput: AnyObject {
    func viewWillAppear()

    func didTapNoProtection()
    func didTapPinProtection()
    func didTapBiometricProtection()
    func didTapChangePinCode()
    func didChangeAppKeyValue(isNewStatusEnabled: Bool)
    func didPickAutoLockTime(value: Int)
}

protocol SettingsLockViewModelOutput: AnyObject {
    func setUIDelegate(_ delegate: SettingsLockUIProtocol)

    var sections: [SettingLockSection] { get }
    var protectionItems: [ProtectionType] { get }
    var autoLockTimeOptions: [Int] { get }

    var biometricType: BiometricType { get }
    var isProtectionEnabled: Bool { get }
    var isBiometricEnabled: Bool { get }
    var isPinCodeEnabled: Bool { get }
    var isAppKeyEnabled: Bool { get }
}

// sourcery: mock
protocol SettingsLockUIProtocol: AnyObject {
    func reloadData()
}
