// Copyright (c) 2022 Proton Technologies AG
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
import struct UIKit.CGFloat
import enum ProtonCore_Utilities.Either

final class AutoDeleteSettingViewModel: SwitchToggleVMProtocol {
    var confirmation: SwitchToggleVMActionConfirmation? {
        SwitchToggleVMActionConfirmation(title: L11n.AutoDeleteSettings.alertTitle,
                                         message: L11n.AutoDeleteSettings.alertMessage,
                                         confirmationButton: L11n.AutoDeleteSettings.alertEnableButton)
    }
    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }

    let currentState: AutoDeleteSpamAndTrashDays

    init(currentState: AutoDeleteSpamAndTrashDays) {
        self.currentState = currentState
    }
}

extension AutoDeleteSettingViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        let newValue: AutoDeleteSpamAndTrashDays = newStatus ? .explicitlyEnabled : .explicitlyDisabled
        guard newValue != currentState else {
            completion(nil)
            return
        }
        //TODO: Call service to update value
    }
}

extension AutoDeleteSettingViewModel: SwitchToggleVMOutput {
    var title: String { L11n.AutoDeleteSettings.settingTitle }
    var sectionNumber: Int { 1 }
    var rowNumber: Int { 1 }
    var headerTopPadding: CGFloat { 8 }
    var footerTopPadding: CGFloat { 8 }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        (L11n.AutoDeleteSettings.rowTitle, currentState == .explicitlyEnabled)
    }

    func sectionHeader(of section: Int) -> String? {
        nil
    }

    func sectionFooter(of section: Int) -> Either<String, NSAttributedString>? {
        Either.left(L11n.AutoDeleteSettings.rowFooterTitle)
    }
}
