// Copyright (c) 2021 Proton AG
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
@testable import ProtonMail

final class SystemUpTimeMock: SystemUpTimeProtocol {
    var localServerTime: TimeInterval
    var localSystemUpTime: TimeInterval
    var systemUpTime: TimeInterval

    func updateLocalSystemUpTime(time: TimeInterval) {
        self.localSystemUpTime = time
    }

    init(localServerTime: TimeInterval,
         localSystemUpTime: TimeInterval,
         systemUpTime: TimeInterval) {
        self.localServerTime = localServerTime
        self.localSystemUpTime = localSystemUpTime
        self.systemUpTime = systemUpTime
    }
}
