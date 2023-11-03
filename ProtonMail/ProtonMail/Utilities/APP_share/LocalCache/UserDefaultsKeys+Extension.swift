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

extension UserDefaultsKeys {
    static let areContactsCached = UserDefaultsKey<Int>(name: "isContactsCached", defaultValue: 0)

    static let isCombineContactOn = UserDefaultsKey<Bool>(name: "combine_contact_flag", defaultValue: false)

    static let isDohOn = UserDefaultsKey<Bool>(name: "doh_flag", defaultValue: true)

    static let isPMMEWarningDisabled = UserDefaultsKey<Bool>(name: "isPM_MEWarningDisabledKey", defaultValue: false)

    static let lastTourVersion = UserDefaultsKey<Int?>(name: "last_tour_viersion", defaultValue: nil)

    static let pinFailedCount = UserDefaultsKey<Int>(name: "lastPinFailedTimes", defaultValue: 0)
}
