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

import ProtonCore_UIFoundations
import UIKit

final class ScheduledSendSpotlightView: SpotlightView {
    init() {
        super.init(
            title: LocalString._general_schedule_send_action,
            message: LocalString._schedule_introduction_view_content,
            icon: Asset.composeScheduleStar
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
