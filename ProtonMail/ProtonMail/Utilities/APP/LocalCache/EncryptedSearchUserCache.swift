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
protocol EncryptedSearchUserCache {
    func isEncryptedSearchOn(of userID: UserID) -> Bool
    func setIsEncryptedSearchOn(of userID: UserID, value: Bool)

    func canDownloadViaMobileData(of userID: UserID) -> Bool
    func setCanDownloadViaMobileData(of userID: UserID, value: Bool)

    // Rebuild search index due to `isRefreshed` in eventAPI response
    func isExternalRefreshed(of userID: UserID) -> Bool
    func setIsExternalRefreshed(of userID: UserID, value: Bool)

    // Only send metric when build index from scratch
    func shouldSendMetric(of userID: UserID) -> Bool
    func setShouldSendMetric(of userID: UserID, value: Bool)

    func indexingPausedByUser(of userID: UserID) -> Bool
    func setIndexingPausedByUser(of userID: UserID, value: Bool)

    // number of times the user has paused indexing during the process
    func numberOfPauses(of userID: UserID) -> Int
    func setNumberOfPauses(of userID: UserID, value: Int)

    // an estimated number of times indexing was interrupted, not including pauses
    func numberOfInterruptions(of userID: UserID) -> Int
    func setNumberOfInterruptions(of userID: UserID, value: Int)

    // the number of seconds that indexing was first estimated to take
    func initialIndexingEstimationTime(of userID: UserID) -> Int
    func setInitialIndexingEstimationTime(of userID: UserID, value: Int)

    func indexingTime(of userID: UserID) -> Int
    func setIndexingTime(of userID: UserID, value: Int)

    func isFirstSearch(of userID: UserID) -> Bool
    func hasSearched(of userID: UserID)

    func logout(of userID: UserID)
    func cleanGlobal()
}

// sourcery: mock
protocol EncryptedSearchDeviceCache {
    var storageLimit: Measurement<UnitInformationStorage> { get set }
    var pauseIndexingDueToNetworkIssues: Bool { get set }
    var pauseIndexingDueToWifiNotDetected: Bool { get set }
    var pauseIndexingDueToOverHeating: Bool { get set }
    var pauseIndexingDueToLowBattery: Bool { get set }
    var interruptStatus: String? { get set }
    var interruptAdvice: String? { get set }
}

final class EncryptedSearchUserDefaultCache: SharedCacheBase, EncryptedSearchUserCache, Service {
    private enum Key {
        // MARK: - User specific flags
        static let encryptedSearchFlag = "encrypted_search_flag"
        static let encryptedSearchDownloadViaMobileData = "encrypted_search_download_via_mobile_data_flag"
        static let encryptedSearchIsExternalRefreshed = "encrypted_search_is_external_refreshed"
        static let encryptedShouldSendMetric = "encrypted_search_should_send_metric"
        static let encryptedSearchIndexingPausedByUser = "encrypted_search_indexing_paused_by_user"
        static let encryptedSearchNumberOfPauses = "encrypted_search_number_of_pauses"
        static let encryptedSearchNumberOfInterruptions = "encrypted_search_number_of_interruptions"
        static let encryptedSearchInitialIndexingTimeEstimate = "encrypted_search_initial_indexing_time_estimate"
        static let encryptedSearchIndexingTime = "encrypted_search_indexing_time"
        static let encryptedSearchIsFirstSearch = "encrypted_search_is_first_search"

        // MARK: - Global flags
        static let encryptedSearchStorageLimit = "encrypted_search_storage_limit_flag"
        static let esPauseIndexingDueToNetworkIssues = "encrypted_search_pause_indexing_network_issues"
        static let esPauseIndexingDueToWiFiNotDetected = "encrypted_search_pause_indexing_wifi_not_detected"
        static let esPauseIndexingDueToOverheating = "encrypted_search_pause_indexing_overheating"
        static let esPauseIndexingDueToLowBattery = "encrypted_search_pause_indexing_low_battery"
        static let esInterruptStatus = "encrypted_search_interrupt_status"
        static let esInterruptAdvice = "encrypted_search_interrupt_advice"
    }

    func isEncryptedSearchOn(of userID: UserID) -> Bool {
        getValueFromDictionary(key: Key.encryptedSearchFlag, userID: userID, defaultValue: false)
    }

    func setIsEncryptedSearchOn(of userID: UserID, value: Bool) {
        updateDictionary(key: Key.encryptedSearchFlag, userID: userID, value: value)
    }

    func canDownloadViaMobileData(of userID: UserID) -> Bool {
        getValueFromDictionary(key: Key.encryptedSearchDownloadViaMobileData, userID: userID, defaultValue: false)
    }

    func setCanDownloadViaMobileData(of userID: UserID, value: Bool) {
        updateDictionary(key: Key.encryptedSearchDownloadViaMobileData, userID: userID, value: value)
    }

    func isExternalRefreshed(of userID: UserID) -> Bool {
        getValueFromDictionary(key: Key.encryptedSearchIsExternalRefreshed, userID: userID, defaultValue: false)
    }

    func setIsExternalRefreshed(of userID: UserID, value: Bool) {
        updateDictionary(key: Key.encryptedSearchIsExternalRefreshed, userID: userID, value: value)
    }

    func shouldSendMetric(of userID: UserID) -> Bool {
        getValueFromDictionary(key: Key.encryptedShouldSendMetric, userID: userID, defaultValue: false)
    }

    func setShouldSendMetric(of userID: UserID, value: Bool) {
        updateDictionary(key: Key.encryptedShouldSendMetric, userID: userID, value: value)
    }

    func indexingPausedByUser(of userID: UserID) -> Bool {
        getValueFromDictionary(key: Key.encryptedSearchIndexingPausedByUser, userID: userID, defaultValue: false)
    }

    func setIndexingPausedByUser(of userID: UserID, value: Bool) {
        updateDictionary(key: Key.encryptedSearchIndexingPausedByUser, userID: userID, value: value)
    }

    func numberOfPauses(of userID: UserID) -> Int {
        getValueFromDictionary(key: Key.encryptedSearchNumberOfPauses, userID: userID, defaultValue: 0)
    }

    func setNumberOfPauses(of userID: UserID, value: Int) {
        updateDictionary(key: Key.encryptedSearchNumberOfPauses, userID: userID, value: value)
    }

    func numberOfInterruptions(of userID: UserID) -> Int {
        getValueFromDictionary(key: Key.encryptedSearchNumberOfInterruptions, userID: userID, defaultValue: 0)
    }

    func setNumberOfInterruptions(of userID: UserID, value: Int) {
        updateDictionary(key: Key.encryptedSearchNumberOfInterruptions, userID: userID, value: value)
    }

    func initialIndexingEstimationTime(of userID: UserID) -> Int {
        getValueFromDictionary(key: Key.encryptedSearchInitialIndexingTimeEstimate, userID: userID, defaultValue: 0)
    }

    func setInitialIndexingEstimationTime(of userID: UserID, value: Int) {
        updateDictionary(key: Key.encryptedSearchInitialIndexingTimeEstimate, userID: userID, value: value)
    }

    func indexingTime(of userID: UserID) -> Int {
        getValueFromDictionary(key: Key.encryptedSearchIndexingTime, userID: userID, defaultValue: 0)
    }

    func setIndexingTime(of userID: UserID, value: Int) {
        updateDictionary(key: Key.encryptedSearchIndexingTime, userID: userID, value: value)
    }

    func isFirstSearch(of userID: UserID) -> Bool {
        getValueFromDictionary(key: Key.encryptedSearchIsFirstSearch, userID: userID, defaultValue: true)
    }

    func hasSearched(of userID: UserID) {
        updateDictionary(key: Key.encryptedSearchIsFirstSearch, userID: userID, value: false)
    }

    func logout(of userID: UserID) {
        deleteValueFromDictionary(key: Key.encryptedSearchFlag, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedSearchDownloadViaMobileData, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedSearchIsExternalRefreshed, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedShouldSendMetric, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedSearchIndexingPausedByUser, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedSearchNumberOfPauses, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedSearchNumberOfInterruptions, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedSearchInitialIndexingTimeEstimate, userID: userID)
        deleteValueFromDictionary(key: Key.encryptedSearchIndexingTime, userID: userID)
    }

    func cleanGlobal() {
        getShared().remove(forKey: Key.encryptedSearchStorageLimit)
        getShared().remove(forKey: Key.esPauseIndexingDueToNetworkIssues)
        getShared().remove(forKey: Key.esPauseIndexingDueToWiFiNotDetected)
        getShared().remove(forKey: Key.esPauseIndexingDueToOverheating)
        getShared().remove(forKey: Key.esPauseIndexingDueToLowBattery)
        getShared().remove(forKey: Key.esInterruptStatus)
        getShared().remove(forKey: Key.esInterruptAdvice)
    }
}

// MARK: - EncryptedSearchDeviceCache
extension EncryptedSearchUserDefaultCache: EncryptedSearchDeviceCache {
    var storageLimit: Measurement<UnitInformationStorage> {
        get {
            if let value = getShared().int(forKey: Key.encryptedSearchStorageLimit) {
                return Measurement(value: Double(value), unit: .bytes)
            } else {
                return Constants.EncryptedSearch.defaultStorageLimit
            }
        }
        set {
            setValue(Int(newValue.converted(to: .bytes).value), forKey: Key.encryptedSearchStorageLimit)
        }
    }

    var pauseIndexingDueToNetworkIssues: Bool {
        get {
            return getShared().bool(forKey: Key.esPauseIndexingDueToNetworkIssues)
        }
        set {
            setValue(newValue, forKey: Key.esPauseIndexingDueToNetworkIssues)
        }
    }

    var pauseIndexingDueToWifiNotDetected: Bool {
        get {
            return getShared().bool(forKey: Key.esPauseIndexingDueToWiFiNotDetected)
        }
        set {
            setValue(newValue, forKey: Key.esPauseIndexingDueToWiFiNotDetected)
        }
    }

    var pauseIndexingDueToOverHeating: Bool {
        get {
            return getShared().bool(forKey: Key.esPauseIndexingDueToOverheating)
        }
        set {
            setValue(newValue, forKey: Key.esPauseIndexingDueToOverheating)
        }
    }

    var pauseIndexingDueToLowBattery: Bool {
        get {
            return getShared().bool(forKey: Key.esPauseIndexingDueToLowBattery)
        }
        set {
            setValue(newValue, forKey: Key.esPauseIndexingDueToLowBattery)
        }
    }

    var interruptStatus: String? {
        get {
            if getShared().object(forKey: Key.esInterruptStatus) == nil {
                return nil
            }
            return getShared().string(forKey: Key.esInterruptStatus)
        }
        set {
            setValue(newValue, forKey: Key.esInterruptStatus)
        }
    }

    var interruptAdvice: String? {
        get {
            if getShared().object(forKey: Key.esInterruptAdvice) == nil {
                return nil
            }
            return getShared().string(forKey: Key.esInterruptAdvice)
        }
        set {
            setValue(newValue, forKey: Key.esInterruptAdvice)
        }
    }
}

extension EncryptedSearchUserDefaultCache {
    private func getValueFromDictionary<T>(key: String, userID: UserID, defaultValue: T) -> T {
        if let cacheValues = getShared().dictionary(forKey: key) as? [String: T],
           let value = cacheValues[userID.rawValue] {
            return value
        } else {
            return defaultValue
        }
    }

    private func updateDictionary<T>(key: String, userID: UserID, value: T) {
        if var cacheValues = getShared().dictionary(forKey: key) as? [String: T] {
            cacheValues[userID.rawValue] = value
            getShared().set(cacheValues, forKey: key)
        } else {
            var newValue: [String: T] = [:]
            newValue[userID.rawValue] = value
            getShared().set(newValue, forKey: key)
        }
    }

    private func deleteValueFromDictionary(key: String, userID: UserID) {
        if var cacheValues = getShared().dictionary(forKey: key) {
            cacheValues.removeValue(forKey: userID.rawValue)
            getShared().set(cacheValues, forKey: key)
        }
    }
}
