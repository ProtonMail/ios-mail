//
//  ServicePlanDataServiceTests.swift
//  ProtonMailTests - Created on 30/08/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import XCTest
@testable import ProtonMail

class ServicePlanDataServiceTests: XCTestCase {
    typealias Subscription = ServicePlanSubscription
    class MockDataStorage: ServicePlanDataStorage {
        var servicePlansDetails: [ServicePlanDetails]?
        var isIAPAvailableOnBE: Bool
        var defaultPlanDetails: ServicePlanDetails?
        var currentSubscription: Subscription?
        
        init(servicePlansDetails: [ServicePlanDetails]?, isIAPAvailableOnBE: Bool, defaultPlanDetails: ServicePlanDetails?, currentSubscription: Subscription?) {
            self.servicePlansDetails = servicePlansDetails
            self.isIAPAvailableOnBE = isIAPAvailableOnBE
            self.defaultPlanDetails = defaultPlanDetails
            self.currentSubscription = currentSubscription
        }
    }
    
    func testDetailsOfServicePlan() {
        let dataStorage = MockDataStorage(servicePlansDetails: [visPlanDetails, proPlanDetails, nonamePlanDetails],
                                          isIAPAvailableOnBE: true,
                                          defaultPlanDetails: freePlanDetails,
                                          currentSubscription: nil)
        let service = ServicePlanDataService(localStorage: dataStorage, apiService: APIService.shared)
        
        let proDetails = service.detailsOfServicePlan(named: proName)
        XCTAssertEqual(proDetails, proPlanDetails)
        
        let defaultDetails = service.detailsOfServicePlan(named: freeName)
        XCTAssertEqual(defaultDetails, freePlanDetails)
    }
    
    // Mock data
    
    lazy var proName = "Pro"
    lazy var visName = "Vis"
    lazy var freeName = "Free"
    lazy var noName = UUID().uuidString
    lazy var proPlanDetails = ServicePlanDetails(features: 42,
                                            iD: UUID().uuidString,
                                            maxAddresses: 42,
                                            maxDomains: 42,
                                            maxMembers: 42,
                                            maxSpace: 42,
                                            maxVPN: 42,
                                            name: proName,
                                            quantity: 42,
                                            services: 42,
                                            title: "Professional",
                                            type: 42)
    lazy var visPlanDetails = ServicePlanDetails(features: 100500,
                                            iD: UUID().uuidString,
                                            maxAddresses: 100500,
                                            maxDomains: 100500,
                                            maxMembers: 100500,
                                            maxSpace: 100500,
                                            maxVPN: 100500,
                                            name: visName,
                                            quantity: 100500,
                                            services: 100500,
                                            title: "Visionary",
                                            type: 100500)
    lazy var nonamePlanDetails = ServicePlanDetails(features: 1,
                                               iD: UUID().uuidString,
                                               maxAddresses: 1,
                                               maxDomains: 1,
                                               maxMembers: 1,
                                               maxSpace: 1,
                                               maxVPN: 1,
                                               name: noName,
                                               quantity: 1,
                                               services: 1,
                                               title: "+1Tb",
                                               type: 1)
    lazy var freePlanDetails = ServicePlanDetails(features: 0,
                                             iD: UUID().uuidString,
                                             maxAddresses: 0,
                                             maxDomains: 0,
                                             maxMembers: 0,
                                             maxSpace: 0,
                                             maxVPN: 0,
                                             name: freeName,
                                             quantity: 0,
                                             services: 0,
                                             title: "Default",
                                             type: 0)
}
