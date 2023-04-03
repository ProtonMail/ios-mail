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

private extension UserCachedStatus.Key {
    static let usersThatFetchedTheirBlockedSenderLists = "usersThatFetchedTheirBlockedSenderLists"
}

extension UserCachedStatus: BlockedSenderFetchStatusProviderProtocol {
    private var userDefaults: UserDefaults {
        SharedCacheBase.getDefault()
    }

    func checkIfBlockedSendersAreFetched(userID: UserID) -> Bool {
        idsOfUsersThatSuccessfullyFetchedBlockedSenders().contains(userID.rawValue)
    }

    func markBlockedSendersAsFetched(userID: UserID) {
        var userIDs = idsOfUsersThatSuccessfullyFetchedBlockedSenders()
        userIDs.insert(userID.rawValue)
        userDefaults.set(Array(userIDs), forKey: Key.usersThatFetchedTheirBlockedSenderLists)
    }

    private func idsOfUsersThatSuccessfullyFetchedBlockedSenders() -> Set<String> {
        let key = Key.usersThatFetchedTheirBlockedSenderLists

        guard let userIDs = userDefaults.array(forKey: key) as? [String] else {
            userDefaults.remove(forKey: key)
            return []
        }

        return Set(userIDs)
    }
}
