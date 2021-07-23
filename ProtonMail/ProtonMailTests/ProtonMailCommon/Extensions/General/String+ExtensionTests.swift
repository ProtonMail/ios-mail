//
//  String+ExtensionTests.swift
//  ProtonMailTests - Created on 28/09/2018.
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

class String_ExtensionTests: XCTestCase {
    
    func testValidEmailAddresses() {
        XCTAssertTrue("jovan@a.org".isValidEmail())
        XCTAssertTrue("jovan@a.co.il".isValidEmail())
        XCTAssertTrue("foo@baz.com".isValidEmail())
        XCTAssertTrue("foo.bar@baz.com".isValidEmail())
        XCTAssertTrue("foo@bar.baz.com".isValidEmail())
        XCTAssertTrue("foo+bar@baz.com".isValidEmail())
        XCTAssertTrue("foo@123.456.789.123".isValidEmail())
        XCTAssertTrue("\"foo\"@baz.com".isValidEmail())
        XCTAssertTrue("123456789@baz.com".isValidEmail())
        XCTAssertTrue("foo@baz-quz.com".isValidEmail())
        XCTAssertTrue("_@baz.com".isValidEmail())
        XCTAssertTrue("________@baz.com".isValidEmail())
        XCTAssertTrue("foo@baz.name".isValidEmail())
        XCTAssertTrue("foo@baz.co.uk".isValidEmail())
        XCTAssertTrue("foo-bar@baz.com".isValidEmail())
        XCTAssertTrue("baz.com@baz.com".isValidEmail())
        XCTAssertTrue("foo.bar+qux@baz.com".isValidEmail())
        XCTAssertTrue("foo.bar-qux@baz.com".isValidEmail())
        XCTAssertTrue("f@baz.com".isValidEmail())
        XCTAssertTrue("_foo@baz.com".isValidEmail())
        XCTAssertTrue("foo/bar=qux@baz.com".isValidEmail())
        XCTAssertTrue("foo@bar--baz.com".isValidEmail())
        XCTAssertTrue("foob*ar@baz.com".isValidEmail())
        XCTAssertTrue("\"foo@bar\"@baz.com".isValidEmail())
        XCTAssertTrue("user.name+tag+sorting@example.com".isValidEmail())
        XCTAssertTrue("example-indeed@strange-example.com".isValidEmail())
        XCTAssertTrue("example@s.example".isValidEmail())
    }
    
    /// some addresses are valid in RFC, but it is ok we don't pass it they are too strange
    func testStrangeEmailAddresses() {
        //The address is only valid according to the broad definition of RFC 5322. It is otherwise invalid.
        XCTAssertFalse("foo@[123.456.789.123]".isValidEmail())
        //Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("foo.\"bar\"@baz.com".isValidEmail())
        //Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("\"foo.(),:;<>[]\".FOO.\"foo@\\ \"FOO\".foo\"@baz.qux.com".isValidEmail())
        //Address is valid for SMTP but has unusual elements
        XCTAssertFalse("\" \"@baz.com".isValidEmail())
        //Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("foo.\"bar\\ qux\"@baz.com".isValidEmail())
        //Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("foo.bar.\"bux\".bar.com@baz.com".isValidEmail())
        //Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("much.\"more\\ unusual\"@example.com".isValidEmail())
        //Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("very.unusual.\"@\".unusual.com@example.com".isValidEmail())
        //Address is valid for SMTP but has unusual elements
        XCTAssertFalse("\"very.(),:;<>[]\\\".VERY.\\\"very@\\\\ \\\"very\\\".unusual\"@strange.example.com".isValidEmail())
        //Address is valid for SMTP but has unusual elements
        XCTAssertFalse("admin@mailserver1".isValidEmail())
        XCTAssertFalse("#!$%&'*+-/=?^_`{}|~@example.org".isValidEmail())
        XCTAssertFalse("\"()<>[]:,;@\\\\\\\"!#$%&'-/=?^_`{}| ~.a\"@example.org".isValidEmail())
    }
    
    //List of Invalid Email Addresses
    func testInvalidEmailAddresses() {
        XCTAssertFalse("jovan@a".isValidEmail())
        XCTAssertFalse("@jovan".isValidEmail())
        XCTAssertFalse("@jovan.ch".isValidEmail())
        
        XCTAssertFalse("plainaddress".isValidEmail())
        XCTAssertFalse("#@%^%#$@#$@#.com".isValidEmail())
        XCTAssertFalse("@example.com".isValidEmail())
        XCTAssertFalse("Joe Smith <email@example.com>".isValidEmail())
        XCTAssertFalse("email.example.com".isValidEmail())
        XCTAssertFalse("email@example@example.com".isValidEmail())
        XCTAssertFalse(".email@example.com".isValidEmail())
        XCTAssertFalse("email.@example.com".isValidEmail())
        XCTAssertFalse("email..email@example.com".isValidEmail())
        XCTAssertFalse("あいうえお@example.com".isValidEmail())
        XCTAssertFalse("email@example.com (Joe Smith)".isValidEmail())
        XCTAssertFalse("email@example".isValidEmail())
        XCTAssertFalse("email@-example.com".isValidEmail())
        XCTAssertFalse("email@example..com".isValidEmail())
        XCTAssertFalse("Abc..123@example.com".isValidEmail())
        XCTAssertFalse("foo.bar@baz.com.".isValidEmail())
        
        XCTAssertFalse("a\"b(c)d,e:f;g<h>I[j\\k]l@baz.com".isValidEmail())
        XCTAssertFalse("foo bar@baz.com".isValidEmail())
        XCTAssertFalse("foo@baz.com-".isValidEmail())
        XCTAssertFalse("foo@baz,qux.com".isValidEmail())
        XCTAssertFalse("foo\\@bar@baz.com".isValidEmail())
        XCTAssertFalse("foo.bar".isValidEmail())
        XCTAssertFalse("@".isValidEmail())
        XCTAssertFalse("@@".isValidEmail())
        XCTAssertFalse(".@".isValidEmail())
        XCTAssertFalse("A@b@c@example.com".isValidEmail())
        // (quoted strings must be dot separated or the only element making up the local-part)
        XCTAssertFalse("just\"not\"right@example.com".isValidEmail())
        // (spaces, quotes, and backslashes may only exist when within quoted strings and preceded by a backslash)
        XCTAssertFalse("this is\"not\\allowed@example.com".isValidEmail())
        // (even if escaped (preceded by a backslash), spaces, quotes, and backslashes must still be contained by quotes)
        XCTAssertFalse("this\\ still\"not\\allowed@example.com".isValidEmail())
        XCTAssertFalse("”(),:;<>[\\]@example.com".isValidEmail())
        XCTAssertFalse("just”not”right@example.com".isValidEmail())
        XCTAssertFalse("this\\ is\"really\"not\\allowed@example.com".isValidEmail())
    }
    
    func testHasImage() {
        let testSrc1 = "<embed type=\"image/svg+xml\" src=\"cid:5d13cdcaf81f4108654c36fc.svg@www.emailprivacytester.com\"/>"
        XCTAssertFalse(testSrc1.hasImage())
        let testSrc2 = "<embed type=\"image/svg+xml\" src='cid:5d13cdcaf81f4108654c36fc.svg@www.emailprivacytester.com'/>"
        XCTAssertFalse(testSrc2.hasImage())
        let testSrc3 = "<img width=\"16\" height=\"16\" src=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=img\"/><img src=\"#\" width=\"16\" height=\"16\"/>"
        XCTAssertTrue(testSrc3.hasImage())
        let testSrc4 = "<script type=\"text/javascript\" src=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=js\">"
         XCTAssertTrue(testSrc4.hasImage())
        let testSrc5 = "<video src=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=video\" width=\"1\" height=\"1\"></video>"
        XCTAssertTrue(testSrc5.hasImage())
        let testSrc6 = "<iframe width=\"1\" height=\"1\" src=\"data:text/html;charset=utf-8,&amp;lt;html&amp;gt;&amp;lt;head&amp;gt;&amp;lt;meta http-equiv=&amp;quot;Refresh&amp;quot; content=&amp;quot;1; URLhttps://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=iframeRefresh&amp;quot;&amp;gt;&amp;lt;/head&amp;gt;&amp;lt;body&amp;gt;&amp;lt;/body&amp;gt;&amp;lt;/html&amp;gt;\"></iframe>"
        XCTAssertTrue(testSrc6.hasImage())
        let testUrl1 = "<p style=\"background-image:url(&#x27;https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=backgroundImage&#x27;);\"></p>"
        XCTAssertTrue(testUrl1.hasImage())
        let testUrl2 = "<p style=\"content:url(&#x27;https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=cssContent&#x27;);\"></p>"
        XCTAssertTrue(testUrl2.hasImage())
        let testposter = "<video poster=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=videoPoster\" width=\"1\" height=\"1\">"
        XCTAssertTrue(testposter.hasImage())
        let testxlink = "<svg viewBox=\"0 0 160 40\" xmlns=\"http://www.w3.org/2000/svg\"><a xlink:href=\"https://developer.mozilla.org/\"><text x=\"10\" y=\"25\">MDN Web Docs</text></a> </svg>"
        XCTAssertTrue(testxlink.hasImage())
        let testBackground1 = "<body background=\"URL\">"
        XCTAssertTrue(testBackground1.hasImage())
    }
}

