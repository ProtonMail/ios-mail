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

import ProtonCorePayments

final class ServicePlanDataStorageImpl: ServicePlanDataStorage {
    private let userDefaults: UserDefaults

    var servicePlansDetails: [Plan]? {
        get {
            userDefaults[.servicePlans]
        }
        set {
            userDefaults[.servicePlans] = newValue
        }
    }

    var defaultPlanDetails: Plan? {
        get {
            userDefaults[.defaultPlanDetails]
        }
        set {
            userDefaults[.defaultPlanDetails] = newValue
        }
    }

    var currentSubscription: Subscription? {
        get {
            userDefaults[.currentSubscription]
        }
        set {
            userDefaults[.currentSubscription] = newValue
        }
    }

    /* TODO NOTE: this should be updated alongside Payments integration */
    var credits: Credits?

    var paymentMethods: [PaymentMethod]? {
        get {
            userDefaults[.paymentMethods]
        }
        set {
            userDefaults[.paymentMethods] = newValue
        }
    }

    var paymentsBackendStatusAcceptsIAP: Bool {
        get {
            userDefaults[.isIAPAvailableOnBE]
        }
        set {
            userDefaults[.isIAPAvailableOnBE] = newValue
        }
    }

    var iapSupportStatus: ProtonCorePayments.IAPSupportStatus {
        get {
            userDefaults[.isIAPAvailableOnBE] ? .enabled : .disabled(localizedReason: nil)
        }
        set {
            switch newValue {
            case .enabled:
                userDefaults[.isIAPAvailableOnBE] = true
            case .disabled:
                userDefaults[.isIAPAvailableOnBE] = false
            }
        }
    }

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}
