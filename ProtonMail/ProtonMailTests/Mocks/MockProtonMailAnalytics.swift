// Copyright (c) 2022 Proton AG
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
import ProtonMailAnalytics

class MockProtonMailAnalytics: ProtonMailAnalyticsProtocol {
    let endPoint: String
    var environment: String?
    var debug: Bool?

    var event: MailAnalyticsEvent?
    var errorEvent: MailAnalyticsErrorEvent?

    required init(endPoint: String) {
        self.endPoint = endPoint
    }

    func setup(environment: String?, debug: Bool) {
        self.environment = environment
        self.debug = debug
    }

    public func track(event: MailAnalyticsEvent, trace: String?) {
        self.event = event
    }

    public func track(error: MailAnalyticsErrorEvent, trace: String?) {
        self.errorEvent = error
    }
}
