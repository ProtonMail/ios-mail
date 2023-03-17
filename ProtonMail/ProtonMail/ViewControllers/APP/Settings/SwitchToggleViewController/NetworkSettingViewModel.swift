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
import ProtonCore_UIFoundations
import enum ProtonCore_Utilities.Either

final class NetworkSettingViewModel: SwitchToggleVMProtocol {
    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }

    private var userCache: DohCacheProtocol
    private var dohSetting: DohStatusProtocol

    init(userCache: DohCacheProtocol, dohSetting: DohStatusProtocol) {
        self.userCache = userCache
        self.dohSetting = dohSetting
    }
}

extension NetworkSettingViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        guard indexPath.row < output.rowNumber else { return }
        dohSetting.status = newStatus ? .on : .off
        userCache.isDohOn = newStatus
        completion(nil)
    }
}

extension NetworkSettingViewModel: SwitchToggleVMOutput {
    var title: String { LocalString._alternative_routing }
    var sectionNumber: Int { 1 }
    var rowNumber: Int { 1 }
    var headerTopPadding: CGFloat { 24 }
    var footerTopPadding: CGFloat { 8 }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        (LocalString._allow_alternative_routing, dohSetting.status == .on)
    }

    func sectionHeader(of section: Int) -> String? {
        LocalString._settings_alternative_routing_title
    }

    func sectionFooter(of section: Int) -> Either<String, NSAttributedString>? {
        let footer = LocalString._settings_alternative_routing_footer
        let learnMore = LocalString._settings_alternative_routing_learn
        let full = String.localizedStringWithFormat(footer, learnMore)

        let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
        let attributedString = NSMutableAttributedString(string: full, attributes: attr)
        if let subrange = full.range(of: learnMore) {
            let nsRange = NSRange(subrange, in: full)
            attributedString.addAttribute(.link,
                                          value: Link.alternativeRouting,
                                          range: nsRange)
        }
        return Either.right(attributedString)
    }
}
