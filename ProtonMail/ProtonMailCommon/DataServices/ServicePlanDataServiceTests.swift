//
//  ServicePlanDataServiceTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 30/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
@testable import ProtonMail

class ServicePlanDataServiceTests: XCTestCase {
    
    struct MockDataStorage: ServicePlanDataStorage {
        var servicePlansDetails: [ServicePlanDetails]?
        var isIAPAvailable: Bool
        var defaultPlanDetails: ServicePlanDetails?
        var currentSubscription: Subscription?
    }
    
    func testDetailsOfServicePlan() {
        let dataStorage = MockDataStorage(servicePlansDetails: [visPlanDetails, proPlanDetails, nonamePlanDetails],
                                          isIAPAvailable: true,
                                          defaultPlanDetails: freePlanDetails,
                                          currentSubscription: nil)
        let service = ServicePlanDataService(localStorage: dataStorage)
        
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
    lazy var proPlanDetails = ServicePlanDetails(amount: 42,
                                            currency: "USD",
                                            cycle: 42,
                                            features: 42,
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
    lazy var visPlanDetails = ServicePlanDetails(amount: 100500,
                                            currency: "EUR",
                                            cycle: 100500,
                                            features: 100500,
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
    lazy var nonamePlanDetails = ServicePlanDetails(amount: 1,
                                               currency: "EUR",
                                               cycle: 1,
                                               features: 1,
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
    lazy var freePlanDetails = ServicePlanDetails(amount: 0,
                                             currency: "EUR",
                                             cycle: 0,
                                             features: 0,
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
