//
//  URL_ExtensionTests.swift
//  ProtonMailTests - Created on 2020/10/16.
//
//
//  Copyright (c) 2020 Proton Technologies AG
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

class URL_ExtensionTests: XCTestCase {

    func test_basic_mail_link() {
        let test_link = "mailto:bogus@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
    }
    
    func test_mutiple_mail_links() throws {
        let test_link = "mailto:bogus@example.com,bogus2@example.com,bogus3@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 3)
        XCTAssertEqual(mailtoData!.to[0], "bogus@example.com")
        XCTAssertEqual(mailtoData!.to[1], "bogus2@example.com")
        XCTAssertEqual(mailtoData!.to[2], "bogus3@example.com")
    }
    
    func test_basic_mail_link_with_cc() {
        
        let test_link = "mailto:bogus@example.com?cc=bogus2@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertEqual(mailtoData!.cc.count, 1)
        XCTAssertEqual(mailtoData!.cc.first, "bogus2@example.com")
    }
    
    func test_basic_mail_link_with_multiple_cc() {
        
        let test_link = "mailto:bogus@example.com?cc=bogus2@example.com,bogus3@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertEqual(mailtoData!.cc.count, 2)
        XCTAssertEqual(mailtoData!.cc[0], "bogus2@example.com")
        XCTAssertEqual(mailtoData!.cc[1], "bogus3@example.com")
    }
    
    func test_basic_mail_link_with_bcc() {
        
        let test_link = "mailto:bogus@example.com?bcc=bogus2@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertEqual(mailtoData!.bcc.count, 1)
        XCTAssertEqual(mailtoData!.bcc.first, "bogus2@example.com")
    }
    
    func test_basic_mail_link_with_multiple_bcc() {
        
        let test_link = "mailto:bogus@example.com?bcc=bogus2@example.com,bogus3@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertEqual(mailtoData!.bcc.count, 2)
        XCTAssertEqual(mailtoData!.bcc[0], "bogus2@example.com")
        XCTAssertEqual(mailtoData!.bcc[1], "bogus3@example.com")
    }
    
    func test_basic_mail_link_with_subject() {
        let test_link = "mailto:bogus@example.com?subject=test%20subject"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertNotNil(mailtoData!.subject)
        XCTAssertEqual(mailtoData!.subject, "test subject")
    }
    
    func test_mail_link_with_body() {
        let test_link = "mailto:bogus@example.com?body=test%20body"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertNotNil(mailtoData!.body)
        XCTAssertEqual(mailtoData!.body, "test body")
    }
    
    func test_mail_link_with_body_and_subject() {
        let test_link = "mailto:bogus@example.com?body=test%20body&subject=test%20subject"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertNotNil(mailtoData!.body)
        XCTAssertEqual(mailtoData!.body, "test body")
        XCTAssertNotNil(mailtoData!.subject)
        XCTAssertEqual(mailtoData!.subject, "test subject")
    }
    
    func test_mail_link_with_all_elements() {
        let test_link = "mailto:bogus@example.com?body=test%20body&subject=test%20subject&cc=cc@example.com,cc2@example.com&bcc=bcc@example.com,bcc2@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData)
        XCTAssertEqual(mailtoData!.to.count, 1)
        XCTAssertEqual(mailtoData!.to.first, "bogus@example.com")
        XCTAssertNotNil(mailtoData!.body)
        XCTAssertEqual(mailtoData!.body, "test body")
        XCTAssertNotNil(mailtoData!.subject)
        XCTAssertEqual(mailtoData!.subject, "test subject")
        XCTAssertEqual(mailtoData!.cc.count, 2)
        XCTAssertEqual(mailtoData!.cc[0], "cc@example.com")
        XCTAssertEqual(mailtoData!.cc[1], "cc2@example.com")
        XCTAssertEqual(mailtoData!.bcc.count, 2)
        XCTAssertEqual(mailtoData!.bcc[0], "bcc@example.com")
        XCTAssertEqual(mailtoData!.bcc[1], "bcc2@example.com")
    }
    
    func test_wrong_mailto_link() {
        let test_link = "malto:bogus@example.com?cc=bogus2@example.com"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNil(mailtoData)
    }
    
    func test_double_body_link() {
        let test_link = "mailto:bogus@example.com?body=test%20body&body=second%20test%20body"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData!.body)
        XCTAssertEqual(mailtoData!.body, "test body")
    }
    
    func test_double_subject_link() {
        let test_link = "mailto:bogus@example.com?subject=test%20subject&subject=second%20test%20subject"
        let url = URL(string: test_link)!
        
        let mailtoData = url.parseMailtoLink()
        XCTAssertNotNil(mailtoData!.subject)
        XCTAssertEqual(mailtoData!.subject, "test subject")
    }
}
