//
//  PlansDataSource.swift
//  ProtonCorePayments - Created on 28.07.23.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCoreServices
import Network
import ProtonCoreObservability

public protocol PlansDataSourceProtocol {
    var isIAPAvailable: Bool { get }
    var availablePlans: AvailablePlans? { get }
    var currentPlan: CurrentPlan? { get }
    var paymentMethods: [PaymentMethod]? { get }
    var willRenewAutomatically: Bool { get }
    var hasPaymentMethods: Bool { get }
    
    func fetchIAPAvailability() async throws
    func fetchAvailablePlans() async throws
    func fetchCurrentPlan() async throws
    func fetchPaymentMethods() async throws
    func createIconURL(iconName: String) -> URL?

    func detailsOfAvailablePlanCorrespondingToIAP(_ iap: InAppPurchasePlan) -> AvailablePlans.AvailablePlan?
    func detailsOfAvailablePlanInstanceCorrespondingToIAP(_ iap: InAppPurchasePlan) -> AvailablePlans.AvailablePlan.Instance?
}

class PlansDataSource: PlansDataSourceProtocol {
    var isIAPAvailable: Bool {
        guard paymentsBackendStatusAcceptsIAP else { return false }
        return true
    }
    
    var paymentsBackendStatusAcceptsIAP: Bool {
        willSet { localStorage.paymentsBackendStatusAcceptsIAP = newValue }
    }
    
    var availablePlans: AvailablePlans?
    var currentPlan: CurrentPlan?
    var paymentMethods: [PaymentMethod]?
    
    private let apiService: APIService
    private let storeKitDataSource: StoreKitDataSourceProtocol
    private let localStorage: ServicePlanDataStorage
    
    init(apiService: APIService,
         storeKitDataSource: StoreKitDataSourceProtocol,
         localStorage: ServicePlanDataStorage) {
        self.apiService = apiService
        self.storeKitDataSource = storeKitDataSource
        self.localStorage = localStorage
        paymentsBackendStatusAcceptsIAP = localStorage.paymentsBackendStatusAcceptsIAP
    }
    
    func fetchIAPAvailability() async throws {
        let paymentStatusRequest = PaymentStatusRequest(api: apiService)
        let paymentStatusResponse = try await paymentStatusRequest.response(responseObject: PaymentStatusResponse())
        paymentsBackendStatusAcceptsIAP = paymentStatusResponse.isAvailable ?? false
    }
    
    func fetchAvailablePlans() async throws {
        let availablePlansRequest = AvailablePlansRequest(api: apiService)
        let availablePlansResponse: AvailablePlansResponse
        do {
            availablePlansResponse = try await availablePlansRequest.response(responseObject: AvailablePlansResponse())
            ObservabilityEnv.report(.availablePlansLoad(status: .http2xx))
        } catch {
            ObservabilityEnv.report(.availablePlansLoad(httpCode: error.httpCode))
            throw error
        }
        let backendAvailablePlans = availablePlansResponse.availablePlans

        guard let backendAvailablePlans else {
            availablePlans = nil
            return
        }

        try await storeKitDataSource.fetchAvailableProducts(availablePlans: backendAvailablePlans)
        availablePlans = storeKitDataSource.filterAccordingToAvailableProducts(availablePlans: backendAvailablePlans)
    }
    
    func fetchCurrentPlan() async throws {
        let currentPlanRequest = CurrentPlanRequest(api: apiService)
        let currentPlanResponse: CurrentPlanResponse
        do {
            currentPlanResponse = try await currentPlanRequest.response(responseObject: CurrentPlanResponse())
            ObservabilityEnv.report(.currentPlanLoad(status: .http2xx))
        } catch {
            ObservabilityEnv.report(.currentPlanLoad(httpCode: error.httpCode))
            throw error
        }
        currentPlan = currentPlanResponse.currentPlan
    }
    
    func fetchPaymentMethods() async throws {
        let paymentMethodsRequest = MethodRequest(api: apiService)
        let paymentMethodsResponse = try await paymentMethodsRequest.response(responseObject: MethodResponse())
        paymentMethods = paymentMethodsResponse.methods
    }
    
    func createIconURL(iconName: String) -> URL? {
        let iconRequest = PlanIconsRequest(api: apiService, iconName: iconName)
        let urlString = apiService.dohInterface.getCurrentlyUsedHostUrl() + iconRequest.path
        return URL(string: urlString)
    }
    
    var willRenewAutomatically: Bool {
        currentPlan?.subscriptions.first?.willRenew ?? false
    }

    func detailsOfAvailablePlanCorrespondingToIAP(_ iap: InAppPurchasePlan) -> AvailablePlans.AvailablePlan? {
        guard let identifier = iap.storeKitProductId else { return nil }
        return availablePlans?.plans.first(where: { plan in
            plan.instances.contains { instance in
                instance.vendors?.apple.productID == identifier && instance.cycle == iap.period.flatMap(Int.init)
            }
        })
    }

    func detailsOfAvailablePlanInstanceCorrespondingToIAP(_ iap: InAppPurchasePlan) -> AvailablePlans.AvailablePlan.Instance? {
        guard let identifier = iap.storeKitProductId else { return nil }
        return availablePlans?.plans.flatMap(\.instances).first(where: { instance in
            instance.vendors?.apple.productID == identifier && instance.cycle == iap.period.flatMap(Int.init)
        })
    }

    var hasPaymentMethods: Bool {
        guard let paymentMethods = paymentMethods else {
            // if we don't know better, we default to assuming the user has payment methods available
            return true
        }
        return !paymentMethods.isEmpty
    }
}
