//
//  Payments.swift
//  ProtonCore-Payments - Created on 16/08/2021.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Services

typealias ListOfIAPIdentifiersGet = () -> ListOfIAPIdentifiers
typealias ListOfIAPIdentifiersSet = (ListOfIAPIdentifiers) -> Void

public final class Payments {

    public static let transactionFinishedNotification = Notification.Name("StoreKitManager.transactionFinished")

    var inAppPurchaseIdentifiers: ListOfIAPIdentifiers
    var reportBugAlertHandler: BugAlertHandler
    let apiService: APIService
    let localStorage: ServicePlanDataStorage
    let canExtendSubscription: Bool
    var paymentsAlertManager: PaymentsAlertManager
    var paymentsApi: PaymentsApiProtocol

    public var alertManager: AlertManagerProtocol {
        get { paymentsAlertManager.alertManager }
        set { paymentsAlertManager.alertManager = newValue }
    }

    public internal(set) lazy var purchaseManager: PurchaseManagerProtocol = PurchaseManager(
        planService: planService, storeKitManager: storeKitManager, paymentsApi: paymentsApi, apiService: apiService
    )

    public internal(set) lazy var planService: ServicePlanDataServiceProtocol = ServicePlanDataService(
        inAppPurchaseIdentifiers: { [weak self] in self?.inAppPurchaseIdentifiers ?? [] },
        paymentsApi: paymentsApi,
        apiService: apiService,
        localStorage: localStorage,
        paymentsAlertManager: paymentsAlertManager
    )

    public internal(set) lazy var storeKitManager: StoreKitManagerProtocol = StoreKitManager(
        inAppPurchaseIdentifiersGet: { [weak self] in self?.inAppPurchaseIdentifiers ?? [] },
        inAppPurchaseIdentifiersSet: { [weak self] in self?.inAppPurchaseIdentifiers = $0 },
        planService: planService,
        paymentsApi: paymentsApi,
        apiService: apiService,
        canExtendSubscription: canExtendSubscription,
        paymentsAlertManager: paymentsAlertManager,
        reportBugAlertHandler: reportBugAlertHandler,
        refreshHandler: { _ in } // default refresh handler does nothing
    )

    public init(inAppPurchaseIdentifiers: ListOfIAPIdentifiers,
                apiService: APIService,
                localStorage: ServicePlanDataStorage,
                alertManager: AlertManagerProtocol? = nil,
                canExtendSubscription: Bool = false,
                reportBugAlertHandler: BugAlertHandler) {
        self.inAppPurchaseIdentifiers = inAppPurchaseIdentifiers
        self.reportBugAlertHandler = reportBugAlertHandler
        self.apiService = apiService
        self.localStorage = localStorage
        self.canExtendSubscription = canExtendSubscription
        paymentsAlertManager = PaymentsAlertManager(alertManager: alertManager ?? AlertManager())
        paymentsApi = PaymentsApiImplementation()
    }
}
