//
//  ServicePlanDetailsTests.swift
//  ProtonMailTests - Created on 31/08/2018.
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

class ServicePlanDetailsTests: XCTestCase {
    
    lazy var plus = ServicePlanDetails(features: 0,
                                       iD: "ziWi-ZOb28XR4sCGFCEpqQbd1FITVWYfTfKYUmV_wKKR3GsveN4HZCh9er5dhelYylEp-fhjBbUPDMHGU699fw==",
                                       maxAddresses: 5,
                                       maxDomains: 1,
                                       maxMembers: 1,
                                       maxSpace: 5368709120,
                                       maxVPN: 0,
                                       name: "plus",
                                       quantity: 1,
                                       services: 1,
                                       title: "ProtonMail Plus",
                                       type: 1)
    lazy var pro = ServicePlanDetails(features: 1,
                                       iD: "rDox3cZuqa4_sMMlxcVZg8pCaUQsMN3IrOLk9kBtO8tZ6t8hiqFwCRIAM09A8U9a0HNNlrTgr8CzXKce58815A==",
                                       maxAddresses: 10,
                                       maxDomains: 2,
                                       maxMembers: 1,
                                       maxSpace: 5368709120,
                                       maxVPN: 0,
                                       name: "professional",
                                       quantity: 1,
                                       services: 1,
                                       title: "ProtonMail Professional",
                                       type: 1)
    lazy var address5 = ServicePlanDetails(features: 1,
                                      iD: "BzHqSTaqcpjIY9SncE5s7FpjBrPjiGOucCyJmwA6x4nTNqlElfKvCQFr9xUa2KgQxAiHv4oQQmAkcA56s3ZiGQ==",
                                      maxAddresses: 5,
                                      maxDomains: 0,
                                      maxMembers: 0,
                                      maxSpace: 0,
                                      maxVPN: 0,
                                      name: "5address",
                                      quantity: 1,
                                      services: 1,
                                      title: "+5 Addresses",
                                      type: 0)
    
    lazy var json = """
    {
       "Plans":[
          {
             "Amount":4800,
             "Name":"plus",
             "ID":"ziWi-ZOb28XR4sCGFCEpqQbd1FITVWYfTfKYUmV_wKKR3GsveN4HZCh9er5dhelYylEp-fhjBbUPDMHGU699fw==",
             "MaxAddresses":5,
             "MaxMembers":1,
             "MaxDomains":1,
             "MaxSpace":5368709120,
             "Services":1,
             "Cycle":12,
             "Type":1,
             "Title":"ProtonMail Plus",
             "MaxVPN":0,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":4800,
             "Name":"vpnbasic",
             "ID":"cjGMPrkCYMsx5VTzPkfOLwbrShoj9NnLt3518AH-DQLYcvsJwwjGOkS8u3AcnX4mVSP6DX2c6Uco99USShaigQ==",
             "MaxAddresses":0,
             "MaxMembers":0,
             "MaxDomains":0,
             "MaxSpace":0,
             "Services":4,
             "Cycle":12,
             "Type":1,
             "Title":"ProtonVPN Basic",
             "MaxVPN":2,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":7500,
             "Name":"professional",
             "ID":"rDox3cZuqa4_sMMlxcVZg8pCaUQsMN3IrOLk9kBtO8tZ6t8hiqFwCRIAM09A8U9a0HNNlrTgr8CzXKce58815A==",
             "MaxAddresses":10,
             "MaxMembers":1,
             "MaxDomains":2,
             "MaxSpace":5368709120,
             "Services":1,
             "Cycle":12,
             "Type":1,
             "Title":"ProtonMail Professional",
             "MaxVPN":0,
             "Features":1,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":9600,
             "Name":"business",
             "ID":"ARy95iNxhniEgYJrRrGvagmzRdnmvxCmjArhv3oZhlevziltNm07euTTWeyGQF49RxFpMqWE_ZGDXEvGV2CEkA==",
             "MaxAddresses":5,
             "MaxMembers":2,
             "MaxDomains":1,
             "MaxSpace":10737418240,
             "Services":1,
             "Cycle":12,
             "Type":1,
             "Title":"Business",
             "MaxVPN":0,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":9600,
             "Name":"vpnplus",
             "ID":"S6oNe_lxq3GNMIMFQdAwOOk5wNYpZwGjBHFr5mTNp9aoMUaCRNsefrQt35mIg55iefE3fTq8BnyM4znqoVrAyA==",
             "MaxAddresses":0,
             "MaxMembers":0,
             "MaxDomains":0,
             "MaxSpace":0,
             "Services":4,
             "Cycle":12,
             "Type":1,
             "Title":"ProtonVPN Plus",
             "MaxVPN":5,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":28800,
             "Name":"visionary",
             "ID":"m-dPNuHcP8N4xfv6iapVg2wHifktAD1A1pFDU95qo5f14Vaw8I9gEHq-3GACk6ef3O12C3piRviy_D43Wh7xxQ==",
             "MaxAddresses":50,
             "MaxMembers":6,
             "MaxDomains":10,
             "MaxSpace":21474836480,
             "Services":5,
             "Cycle":12,
             "Type":1,
             "Title":"Visionary",
             "MaxVPN":10,
             "Features":1,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":900,
             "Name":"1gb",
             "ID":"vUZGQHCgdhbDi3qBKxtnuuagOsgaa08Wpu0WLdaqVIKGI5FM7KwIrDB4IprPbhThXJ_5Pb90bkGlHM1ARMYYrQ==",
             "MaxAddresses":0,
             "MaxMembers":0,
             "MaxDomains":0,
             "MaxSpace":1073741824,
             "Services":1,
             "Cycle":12,
             "Type":0,
             "Title":"+1 GB",
             "MaxVPN":0,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":900,
             "Name":"5address",
             "ID":"BzHqSTaqcpjIY9SncE5s7FpjBrPjiGOucCyJmwA6x4nTNqlElfKvCQFr9xUa2KgQxAiHv4oQQmAkcA56s3ZiGQ==",
             "MaxAddresses":5,
             "MaxMembers":0,
             "MaxDomains":0,
             "MaxSpace":0,
             "Services":1,
             "Cycle":12,
             "Type":0,
             "Title":"+5 Addresses",
             "MaxVPN":0,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":1800,
             "Name":"1domain",
             "ID":"Xz2wY0Wq9cg1LKwchjWR05vF62QUPZ3h3Znku2ramprCLWOr_5kB8mcDFxY23lf7QspHOWWflejL6kl04f-a-Q==",
             "MaxAddresses":0,
             "MaxMembers":0,
             "MaxDomains":1,
             "MaxSpace":0,
             "Services":1,
             "Cycle":12,
             "Type":0,
             "Title":"+1 Domain",
             "MaxVPN":0,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":1800,
             "Name":"1vpn",
             "ID":"gzKDANARz0i8OHhGuZV-oFfURju0I3XeW_hNn09g13dS_NJ57UbW420UAcWb-0s93xoav22O_jARq61FyL3guw==",
             "MaxAddresses":0,
             "MaxMembers":0,
             "MaxDomains":0,
             "MaxSpace":0,
             "Services":4,
             "Cycle":12,
             "Type":0,
             "Title":"+1 VPN Connection",
             "MaxVPN":1,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          },
          {
             "Amount":7500,
             "Name":"1member",
             "ID":"1H8EGg3J1QpSDL6K8hGsTvwmHXdtQvnxplUMePE7Hruen5JsRXvaQ75-sXptu03f0TCO-he3ymk0uhrHx6nnGQ==",
             "MaxAddresses":5,
             "MaxMembers":1,
             "MaxDomains":0,
             "MaxSpace":5368709120,
             "Services":1,
             "Cycle":12,
             "Type":0,
             "Title":"+1 User",
             "MaxVPN":0,
             "Features":0,
             "Currency":"USD",
             "Quantity":1
          }
       ],
       "Code":1000
    }
    """

    func testDecode() {
        guard let data = self.json.data(using: .utf8),
            let dictionary = ((try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String, Any>) as Dictionary<String, Any>??) else
        {
            XCTAssertTrue(false, "Failed to serialize mock data")
            return
        }

        let parser = GetServicePlansResponse()
        XCTAssertTrue(parser.ParseResponse(dictionary), "Failed to parse plans list")
        
        let plans: Array<ServicePlanDetails>? = parser.availableServicePlans
        XCTAssertNotNil(plans, "Failed to parse plans list")
        XCTAssertFalse(plans!.isEmpty, "Failed to parse plans list")
        
        // no id arrived
        let plus = plans?.first(where: { $0.name == "plus" })
        XCTAssertEqual(plus, self.plus)
        
        // everything good
        let pro = plans?.first(where: { $0.name == "professional" })
        XCTAssertEqual(pro, self.pro)
    }
    
    func testMerge() {
        // TODO: when merge logic will be implemented
    }
    
    func testSubscription() {
        let subscription = ServicePlanSubscription(start: .distantPast,
                                        end: .distantFuture,
                                        planDetails: [self.address5, self.pro],
                                        defaultPlanDetails: nil,
                                        paymentMethods: [.init(iD: "424242", type: .card)])
        
        XCTAssertEqual(subscription.plan, .pro)
        XCTAssertEqual(subscription.details, [self.address5, self.pro].merge())
        XCTAssertTrue(subscription.hadOnlinePayments)
    }
}
