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
import ProtonCoreServices
import enum ProtonCoreUtilities.Either
import struct UIKit.CGFloat

final class AutoDeleteSettingViewModel: SwitchToggleVMProtocol {
    var confirmationOnEnable: SwitchToggleVMActionConfirmation? {
        SwitchToggleVMActionConfirmation(title: L10n.AutoDeleteSettings.enableAlertTitle,
                                         message: L10n.AutoDeleteSettings.enableAlertMessage,
                                         confirmationButton: L10n.AutoDeleteSettings.enableAlertButton)
    }
    var confirmationOnDisable: SwitchToggleVMActionConfirmation? {
        nil
    }
    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }

    private var autoDeleteSpamAndTrashDaysProvider: AutoDeleteSpamAndTrashDaysProvider
    private let apiService: APIService

    init(
        _ autoDeleteSpamAndTrashDaysProvider: AutoDeleteSpamAndTrashDaysProvider,
        apiService: APIService
    ) {
        self.autoDeleteSpamAndTrashDaysProvider = autoDeleteSpamAndTrashDaysProvider
        self.apiService = apiService
    }
}

extension AutoDeleteSettingViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        guard newStatus != autoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabled else {
            completion(nil)
            return
        }
        let request = UpdateAutoDeleteSpamAndTrashDaysRequest(shouldEnable: newStatus)
        apiService.perform(
            request: request,
            response: VoidResponse()
        ) { [weak self] _, response in
            if let error = response.error?.toNSError {
                completion(error)
            } else {
                self?.autoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabled = newStatus
                completion(nil)
            }
        }
    }
}

extension AutoDeleteSettingViewModel: SwitchToggleVMOutput {
    var title: String { L10n.AutoDeleteSettings.settingTitle }
    var sectionNumber: Int { 1 }
    var rowNumber: Int { 1 }
    var headerTopPadding: CGFloat { 8 }
    var footerTopPadding: CGFloat { 8 }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        (L10n.AutoDeleteSettings.rowTitle, autoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabled)
    }

    func sectionHeader() -> String? {
        nil
    }

    func sectionFooter(section: Int) -> Either<String, NSAttributedString>? {
        Either.left(L10n.AutoDeleteSettings.rowFooterTitle)
    }
}
