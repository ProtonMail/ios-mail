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

import DesignSystem
import proton_app_uniffi
import SwiftUI

extension GeneralActions {

    var displayData: ActionDisplayData {
        switch self {
        case .viewMessageInLightMode:
            .init(title: L10n.Action.renderInLightMode, image: DS.Icon.icSun)
        case .saveAsPdf:
            .init(title: L10n.Action.saveAsPDF, image: DS.Icon.icFilePDF)
        case .print:
            .init(title: L10n.Action.print, image: DS.Icon.icPrinter)
        case .viewHeaders:
            .init(title: L10n.Action.viewHeaders, image: DS.Icon.icFileLines)
        case .viewHtml:
            .init(title: L10n.Action.viewHTML, image: DS.Icon.icCode)
        case .reportPhishing:
            .init(title: L10n.Action.reportPhishing, image: DS.Icon.icHook)
        }
    }

}
