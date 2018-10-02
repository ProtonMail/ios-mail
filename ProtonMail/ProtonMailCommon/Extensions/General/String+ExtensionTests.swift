//
//  String+ExtensionTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 28/09/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
    
    //TODO:: Figure out later
    func testShouldInvalidButPassed() {
        //The address is only valid according to the broad definition of RFC 5322. It is otherwise invalid.
        //The local part of the address is too long
        //XCTAssertFalse("foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo@baz.com".isValidEmail())
        //    1234567890123456789012345678901234567890123456789012345678901234+x@example.com (local part is longer than 64 characters)
        //XCTAssertFalse("email@example.web".isValidEmail())
        //Address is valid but the Top Level Domain begins with a number
        //XCTAssertFalse("email@111.222.333.44444".isValidEmail())
    }
}

