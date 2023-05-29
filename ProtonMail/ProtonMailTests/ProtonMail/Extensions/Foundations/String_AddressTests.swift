// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

final class String_AddressTests: XCTestCase {

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
        // The address is only valid according to the broad definition of RFC 5322. It is otherwise invalid.
        XCTAssertFalse("foo@[123.456.789.123]".isValidEmail())
        // Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("foo.\"bar\"@baz.com".isValidEmail())
        // Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("\"foo.(),:;<>[]\".FOO.\"foo@\\ \"FOO\".foo\"@baz.qux.com".isValidEmail())
        // Address is valid for SMTP but has unusual elements
        XCTAssertFalse("\" \"@baz.com".isValidEmail())
        // Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("foo.\"bar\\ qux\"@baz.com".isValidEmail())
        // Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("foo.bar.\"bux\".bar.com@baz.com".isValidEmail())
        // Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("much.\"more\\ unusual\"@example.com".isValidEmail())
        // Address contains deprecated elements but may still be valid in restricted contexts
        XCTAssertFalse("very.unusual.\"@\".unusual.com@example.com".isValidEmail())
        // Address is valid for SMTP but has unusual elements
        XCTAssertFalse("\"very.(),:;<>[]\\\".VERY.\\\"very@\\\\ \\\"very\\\".unusual\"@strange.example.com".isValidEmail())
        // Address is valid for SMTP but has unusual elements
        XCTAssertFalse("admin@mailserver1".isValidEmail())
        XCTAssertFalse("#!$%&'*+-/=?^_`{}|~@example.org".isValidEmail())
        XCTAssertFalse("\"()<>[]:,;@\\\\\\\"!#$%&'-/=?^_`{}| ~.a\"@example.org".isValidEmail())
    }

    // List of Invalid Email Addresses
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

    func testCanonicalizeEmailForValidAddressWhenSchemeIsProton() {
        var address = "tester+unit@pm.me"
        var result = address.canonicalizeEmail(scheme: .proton)
        XCTAssertEqual(result, "tester@pm.me")

        address = "TESTER+UNIT+TEST@PM.ME"
        result = address.canonicalizeEmail(scheme: .proton)
        XCTAssertEqual(result, "tester@pm.me")

        address = "test.er_unit-test@pm.me"
        result = address.canonicalizeEmail(scheme: .proton)
        XCTAssertEqual(result, "testerunittest@pm.me")
    }

    func testCanonicalizeEmailForInvalidAddressWhenSchemeIsProton() {
        var address = "IAmNotAddress"
        var result = address.canonicalizeEmail(scheme: .proton)
        XCTAssertEqual(result, "iamnotaddress")

        address = "jovan@a"
        result = address.canonicalizeEmail(scheme: .proton)
        XCTAssertEqual(result, "jovan@a")
    }

    func testCanonicalizeEmailWhenSchemeIsGmail() {
        var address = "tester+unit@gmail.com"
        var result = address.canonicalizeEmail(scheme: .gmail)
        XCTAssertEqual(result, "tester@gmail.com")

        address = "TESTER+UNIT+TEST@GMAIL.COM"
        result = address.canonicalizeEmail(scheme: .gmail)
        XCTAssertEqual(result, "tester@gmail.com")

        address = "test.er_unit-test@gmail.com"
        result = address.canonicalizeEmail(scheme: .gmail)
        XCTAssertEqual(result, "tester_unit-test@gmail.com")

        address = "IAmNotAddress"
        result = address.canonicalizeEmail(scheme: .gmail)
        XCTAssertEqual(result, "iamnotaddress")

        address = "jovan@a"
        result = address.canonicalizeEmail(scheme: .gmail)
        XCTAssertEqual(result, "jovan@a")
    }
}
