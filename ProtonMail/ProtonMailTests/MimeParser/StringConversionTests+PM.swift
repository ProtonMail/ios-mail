//
//  StringConversionPMTests.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import XCTest
@testable import ProtonMail

class StringConversionPMTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
//    func testExample() {
//        let test1 = "[https://www.facebook.com/100028260670776/publickey/verify/?e=1&fp=0848218B92840DD5D4531BE9ED19D085B7A994EA&lu=1535408302&ext=1535667502&hash=AeRROZSxqjKeTf73]"
//
//        let test2 = "<a href=\"https://www.facebook.com/100028260670776/publickey/verify/?e=1&amp;fp=0848218B92840DD5D4531BE9ED19D085B7A994EA&amp;lu=1535408302&amp;ext=1535667502&amp;hash=AeRROZSxqjKeTf73\" target=\"_blank\" style=\"color:#3b5998;text-decoration:none;\">是，請將 Facebook 寄送給我的通知電子郵件加密。</a>"
//        let mimeMsg = MIMEMessage(string: test1)
//        let mimeMsg1 = MIMEMessage(string: test2)
//
//
//        let data = test1.data(using: .ascii)!
//        let converted = data.convertFromMangledUTF8()
//        let s = String(malformedUTF8: converted)
//        print(s)
//        let unpacked = String(data: converted, encoding: .utf8)
//
//        XCTAssert(true, "Pass")
//    }
//
//    func testConvertURL() {
//        let raw = "[https://www.facebook.com/100028260670776/publickey/verify/?e=1&fp=0848218B92840DD5D4531BE9ED19D085B7A994EA&lu=1535408302&ext=1535667502&hash=AeRROZSxqjKeTf73]"
//        let data = raw.data(using: .ascii)!
//        let converted = data.convertFromMangledUTF8()
//
//        let s = String(malformedUTF8: converted)
//        print(s)
//        let unpacked = String(data: converted, encoding: .utf8)
////        XCTAssertEqual(raw, unpacked, "Failed to extract URL \(raw) \n->\n\(unpacked!)")
//    }
    
    
}
