// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

final class BackgroundTimer {
    private static let lastForegroundDateKey = "lastForegroundDateKey"
    private let userDefaults: UserDefaults
    static let shared = BackgroundTimer()
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func willEnterBackgroundOrTerminate(date: Date? = nil) {
        updateLastForegroundDate(date: date)
    }

    func updateLastForegroundDate(date: Date? = nil) {
        userDefaults.set(date ?? Date(), forKey: Self.lastForegroundDateKey)
    }

    var wasInBackgroundForMoreThanOneHour: Bool {
        guard let lastForegroundDate = userDefaults.value(forKey: Self.lastForegroundDateKey) as? Date else {
            return false
        }
        return Date() >= lastForegroundDate.addingTimeInterval(TimeInterval.oneHour)
    }
}

private extension TimeInterval {
    static let oneHour: TimeInterval = 3_600
}
