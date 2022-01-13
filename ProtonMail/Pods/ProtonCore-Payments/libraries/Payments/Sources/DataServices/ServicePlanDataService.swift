//
//  ServicePlanDataService.swift
//  ProtonCore-Payments - Created on 17/08/2018.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import ProtonCore_DataModel
import ProtonCore_Log
import ProtonCore_Services

public protocol ServicePlanDataServiceProtocol: Service, AnyObject {

    var isIAPAvailable: Bool { get }
    var credits: Credits? { get }
    var plans: [Plan] { get }
    var defaultPlanDetails: Plan? { get }
    var availablePlansDetails: [Plan] { get }
    var currentSubscription: Subscription? { get set }

    var currentSubscriptionChangeDelegate: CurrentSubscriptionChangeDelegate? { get set }

    func detailsOfServicePlan(named name: String) -> Plan?

    /// This is a blocking network call that should never be called from the main thread — there's an assertion ensuring that
    func updateServicePlans() throws
    func updateServicePlans(callBlocksOnParticularQueue: DispatchQueue?, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func updateCurrentSubscription(callBlocksOnParticularQueue: DispatchQueue?, updateCredits: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func updateCredits(callBlocksOnParticularQueue: DispatchQueue?, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
}

public extension ServicePlanDataServiceProtocol {
    func updateServicePlans(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        updateServicePlans(callBlocksOnParticularQueue: .main, success: success, failure: failure)
    }
    func updateCurrentSubscription(updateCredits: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        updateCurrentSubscription(callBlocksOnParticularQueue: .main, updateCredits: updateCredits, success: success, failure: failure)
    }
    func updateCredits(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        updateCredits(callBlocksOnParticularQueue: .main, success: success, failure: failure)
    }
}

public protocol ServicePlanDataStorage: AnyObject {
    var servicePlansDetails: [Plan]? { get set }
    var defaultPlanDetails: Plan? { get set }
    var currentSubscription: Subscription? { get set }
    var credits: Credits? { get set }
    var paymentsBackendStatusAcceptsIAP: Bool { get set }
    
    /// Informs about the result of the payments backend status call /payments/v4/status concerning IAP acceptance
    @available(*, deprecated, renamed: "paymentsBackendStatusAcceptsIAP")
    var isIAPUpgradePlanAvailable: Bool { get set }
}

public extension ServicePlanDataStorage {
    @available(*, deprecated, renamed: "paymentsBackendStatusAcceptsIAP")
    var isIAPUpgradePlanAvailable: Bool {
        get { paymentsBackendStatusAcceptsIAP }
        set { paymentsBackendStatusAcceptsIAP = newValue }
    }
}

public struct Credits {
    public let credit: Double
    public let currency: String
    
    public init(credit: Double, currency: String) {
        self.credit = credit
        self.currency = currency
    }
}

public protocol CurrentSubscriptionChangeDelegate: AnyObject {
    func onCurrentSubscriptionChange(old: Subscription?, new: Subscription?)
}

final class ServicePlanDataService: ServicePlanDataServiceProtocol {
    public let service: APIService

    private let paymentsApi: PaymentsApiProtocol
    private let localStorage: ServicePlanDataStorage

    let listOfIAPIdentifiers: ListOfIAPIdentifiersGet

    public weak var currentSubscriptionChangeDelegate: CurrentSubscriptionChangeDelegate?

    public var isIAPAvailable: Bool {
        guard paymentsBackendStatusAcceptsIAP else { return false }
        return true
    }

    public var availablePlansDetails: [Plan] {
        willSet { localStorage.servicePlansDetails = newValue }
    }
    
    public var paymentsBackendStatusAcceptsIAP: Bool {
        willSet { localStorage.paymentsBackendStatusAcceptsIAP = newValue }
    }

    @available(*, deprecated, renamed: "paymentsBackendStatusAcceptsIAP")
    public var isIAPUpgradePlanAvailable: Bool {
        get { paymentsBackendStatusAcceptsIAP }
        set { paymentsBackendStatusAcceptsIAP = newValue }
    }

    public var defaultPlanDetails: Plan? {
        willSet { localStorage.defaultPlanDetails = newValue }
    }

    public var plans: [Plan] {
        let subscriptionDetails = currentSubscription.flatMap { $0.planDetails } ?? []
        let defaultDetails = defaultPlanDetails.map { [$0] } ?? []
        return subscriptionDetails + availablePlansDetails + defaultDetails
    }

    public var currentSubscription: Subscription? {
        willSet { localStorage.currentSubscription = newValue }
        didSet { currentSubscriptionChangeDelegate?.onCurrentSubscriptionChange(old: oldValue, new: currentSubscription) }
    }

    public var credits: Credits? {
        willSet { localStorage.credits = newValue }
    }

    init(inAppPurchaseIdentifiers: @escaping ListOfIAPIdentifiersGet,
         paymentsApi: PaymentsApiProtocol,
         apiService: APIService,
         localStorage: ServicePlanDataStorage,
         paymentsAlertManager: PaymentsAlertManager) {
        self.localStorage = localStorage
        self.availablePlansDetails = localStorage.servicePlansDetails ?? []
        self.paymentsBackendStatusAcceptsIAP = localStorage.paymentsBackendStatusAcceptsIAP
        self.defaultPlanDetails = localStorage.defaultPlanDetails
        self.currentSubscription = localStorage.currentSubscription
        self.paymentsApi = paymentsApi
        self.service = apiService
        self.listOfIAPIdentifiers = inAppPurchaseIdentifiers
    }

    public func detailsOfServicePlan(named name: String) -> Plan? {
        if InAppPurchasePlan.isThisAFreePlan(protonName: name) {
            return defaultPlanDetails
        } else {
            return availablePlansDetails.first(where: { $0.name == name })
        }
    }
}

extension ServicePlanDataService {
    public func updateServicePlans(callBlocksOnParticularQueue: DispatchQueue?, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        performWork(work: { try self.updateServicePlans() },
                    callBlocksOnParticularQueue: callBlocksOnParticularQueue, success: success, failure: failure)
    }

    public func updateServicePlans() throws {
        guard Thread.isMainThread == false else {
            assertionFailure("This is a blocking network request, should never be called from main thread")
            throw AwaitInternalError.synchronousCallPerformedFromTheMainThread
        }
        
        // get API atatus
        let statusApi = self.paymentsApi.statusRequest(api: self.service)
        let statusRes = try statusApi.awaitResponse()
        self.paymentsBackendStatusAcceptsIAP = statusRes.isAvailable ?? false

        // get service plans
        let servicePlanApi = self.paymentsApi.plansRequest(api: self.service)
        let servicePlanRes = try servicePlanApi.awaitResponse()
        self.availablePlansDetails = servicePlanRes.availableServicePlans?
            .filter { InAppPurchasePlan.nameIsPresentInIAPIdentifierList(name: $0.name, identifiers: self.listOfIAPIdentifiers()) }
            .sorted { $0.pricing(for: String(12)) ?? 0 > $1.pricing(for: String(12)) ?? 0 }
            ?? []

        let defaultServicePlanApi = self.paymentsApi.defaultPlanRequest(api: self.service)
        let defaultServicePlanRes = try defaultServicePlanApi.awaitResponse()
        self.defaultPlanDetails = defaultServicePlanRes.defaultServicePlanDetails
    }

    public func updateCurrentSubscription(callBlocksOnParticularQueue: DispatchQueue?, updateCredits: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        performWork(work: { try self.updateCurrentSubscription(updateCredits: updateCredits) },
                    callBlocksOnParticularQueue: callBlocksOnParticularQueue, success: success, failure: failure)
    }
    
    public func updateCredits(callBlocksOnParticularQueue: DispatchQueue?, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        performWork(work: { try self.updateCredits() },
                    callBlocksOnParticularQueue: callBlocksOnParticularQueue, success: success, failure: failure)
    }
    
    private func performWork(work: @escaping () throws -> Void, callBlocksOnParticularQueue: DispatchQueue?,
                             success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try work()
                guard let callBlocksOnParticularQueue = callBlocksOnParticularQueue else {
                    success()
                    return
                }
                callBlocksOnParticularQueue.async {
                    success()
                }
            } catch {
                guard let callBlocksOnParticularQueue = callBlocksOnParticularQueue else {
                    failure(error)
                    return
                }
                callBlocksOnParticularQueue.async {
                    failure(error)
                }
            }
        }
    }
    
    private func updateCurrentSubscription(updateCredits: Bool) throws {
        guard Thread.isMainThread == false else {
            assertionFailure("This is a blocking network request, should never be called from main thread")
            throw AwaitInternalError.synchronousCallPerformedFromTheMainThread
        }

        do {
            if updateCredits {
                try self.updateCredits()
            }
            let subscriptionApi = self.paymentsApi.getSubscriptionRequest(api: self.service)
            let subscriptionRes = try subscriptionApi.awaitResponse()
            self.currentSubscription = subscriptionRes.subscription

            let organizationsApi = self.paymentsApi.organizationsRequest(api: self.service)
            let organizationsRes = try organizationsApi.awaitResponse()
            self.currentSubscription?.organization = organizationsRes.organization

        } catch {
            if error.isNoSubscriptionError {
                self.currentSubscription = .userHasNoPlanAKAFreePlan
                self.credits = nil
            } else if error.accessTokenDoesNotHaveSufficientScopeToAccessResource {
                self.currentSubscription = .userHasUnsufficientScopeToFetchSubscription
                self.credits = nil
            } else {
                self.currentSubscription = nil
                self.credits = nil
                throw error
            }
        }
    }
    
    private func updateCredits() throws {
        do {
            let user = try self.paymentsApi.getUser(api: self.service)
            self.credits = Credits(credit: Double(user.credit) / 100, currency: user.currency)
        } catch {
            self.credits = nil
            throw error
        }
    }
}
