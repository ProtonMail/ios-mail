// Copyright (c) 2024 Proton Technologies AG
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
import enum ProtonCoreUtilities.Either

final class MessageSwipeNavigationViewModel: SwitchToggleVMProtocol {
    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }
    private var userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}

extension MessageSwipeNavigationViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        userDefaults[.isMessageSwipeNavigationEnabled] = newStatus
        completion(nil)
    }
}

extension MessageSwipeNavigationViewModel: SwitchToggleVMOutput {
    var title: String { L10n.MessageNavigation.settingTitle }
    var sectionNumber: Int { 1 }
    var rowNumber: Int { 1 }
    var headerTopPadding: CGFloat { 24 }
    var footerTopPadding: CGFloat { 8 }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        (L10n.MessageNavigation.settingTitle, userDefaults[.isMessageSwipeNavigationEnabled])
    }

    func sectionHeader() -> String? { nil }

    func sectionFooter(section: Int) -> ProtonCoreUtilities.Either<String, NSAttributedString>? {
        .left(L10n.MessageNavigation.settingDesc)
    }
}
