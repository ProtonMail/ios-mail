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

final class ContactCombineViewModel: SwitchToggleVMProtocol {
    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }

    private var combineContactCache: ContactCombinedCacheProtocol

    init(combineContactCache: ContactCombinedCacheProtocol) {
        self.combineContactCache = combineContactCache
    }
}

extension ContactCombineViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        combineContactCache.isCombineContactOn = newStatus
        completion(nil)
    }
}

extension ContactCombineViewModel: SwitchToggleVMOutput {
    var title: String { LocalString._combined_contacts }
    var sectionNumber: Int { 1 }
    var rowNumber: Int { 1 }
    var headerTopPadding: CGFloat { 8 }
    var footerTopPadding: CGFloat { 8 }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        (LocalString._settings_title_of_combined_contact, combineContactCache.isCombineContactOn)
    }

    func sectionHeader(of section: Int) -> String? {
        nil
    }

    func sectionFooter(of section: Int) -> String? {
        LocalString._settings_footer_of_combined_contact
    }
}
