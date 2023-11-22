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

// sourcery: mock
protocol ContactsSyncCache {
    func setHistoryToken(_ token: Data, for userID: UserID)
    func historyToken(for userID: UserID) -> Data?
}

struct ContactsSyncDefaults: ContactsSyncCache {
    private let historyTokenPerUserKey = "historyTokenPerUser"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func setHistoryToken(_ token: Data, for userID: UserID) {
        var historyTokens = loadHistoryTokenPerUserKey()
        historyTokens[userID.rawValue] = token
        userDefaults.setValue(historyTokens, forKey: historyTokenPerUserKey)
    }

    func historyToken(for userID: UserID) -> Data? {
        let historyTokens = loadHistoryTokenPerUserKey()
        return historyTokens[userID.rawValue]
    }

    private func loadHistoryTokenPerUserKey() -> [String: Data] {
        userDefaults.dictionary(forKey: historyTokenPerUserKey) as? [String: Data] ?? [:]
    }
}
