//
//  ServicePlanDataServiceTests.swift
//  ProtonMailTests - Created on 30/08/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import XCTest
@testable import ProtonMail

class ServicePlanDataServiceTests: XCTestCase {
    typealias Subscription = ServicePlanSubscription
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
