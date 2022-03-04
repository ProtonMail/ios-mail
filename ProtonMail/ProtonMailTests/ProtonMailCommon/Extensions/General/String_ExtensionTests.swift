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

final class String_ExtensionTests: XCTestCase {

    func testHasRe() {
        XCTAssertTrue("Re: Test mail".hasRe())
        XCTAssertFalse("Test mail".hasRe())
    }

    func testHasFw() {
        XCTAssertTrue("Fw: Test mail".hasFw())
        XCTAssertFalse("Test mail".hasFw())
    }

    func testHasFwd() {
        XCTAssertTrue("Fwd: Test mail".hasFwd())
        XCTAssertFalse("Test mail".hasFwd())
    }

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

    func testTrim() {
        XCTAssertEqual("  abc ".trim(), "abc")
        XCTAssertEqual("　　 abc 　　".trim(), "abc")
    }

    func testLn2Br() {
        XCTAssertEqual("a\r\nbc\n".ln2br(), "a<br />bc<br />")
        XCTAssertEqual("abc".ln2br(), "abc")
    }

    func testRmln() {
        XCTAssertEqual("a\nb".rmln(), "ab")
        XCTAssertEqual(#"a\b"#.rmln(), #"a\b"#)
    }

    func testlr2lrln() {
        XCTAssertEqual("\r\n".lr2lrln(), "\r\n")
        XCTAssertEqual("\r".lr2lrln(), "\r\n")
        XCTAssertEqual("\r\t".lr2lrln(), "\r\n\t")
    }

    func testDecodeHTML() {
        XCTAssertEqual("abc".decodeHtml(), "abc")
        XCTAssertEqual("&amp;&quot;&#039;&#39;&lt;&gt;".decodeHtml(), "&\"''<>")
    }

    func testEncodeHTML() {
        XCTAssertEqual("abc".encodeHtml(), "abc")
        XCTAssertEqual("&\"''<><br />".encodeHtml(), "&amp;&quot;&#039;&#039;&lt;&gt;<br />")
    }

    func testPreg_match() {
        XCTAssertFalse("abc".preg_match("ccc"))
        XCTAssertTrue("abccdew".preg_match("cc"))
    }

    func testPreg_range() {
        guard let range = "abc".preg_range("bc") else {
            XCTFail("Should have range")
            return
        }
        let subString = "abc"[range]
        XCTAssertEqual(subString, "bc")
        XCTAssertNil("abc".preg_range("eifl"))
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

    func testRandomString() {
        XCTAssertEqual(String.randomString(3).count, 3)
        XCTAssertTrue(String.randomString(0).isEmpty)
    }

    func testEncodeBase64() {
        XCTAssertEqual("This is a sample string".encodeBase64(),
                       "VGhpcyBpcyBhIHNhbXBsZSBzdHJpbmc=")
        XCTAssertEqual("Welcome to protonmail".encodeBase64(),
                       "V2VsY29tZSB0byBwcm90b25tYWls")
    }

    func testDecodeBase64() {
        XCTAssertEqual("VGhpcyBpcyBhIHNhbXBsZSBzdHJpbmc=".decodeBase64(),
                       "This is a sample string")
        XCTAssertEqual("V2VsY29tZSB0byBwcm90b25tYWls".decodeBase64(),
                       "Welcome to protonmail")
    }

    func testParseObject() {
        XCTAssertEqual("".parseObject(), [:])
        let dict = "{\"dev\":\"Dev\",\"name\":\"Tester\"}".parseObject()
        XCTAssertEqual(dict["dev"], "Dev")
        XCTAssertEqual(dict["name"], "Tester")

        let dict2 = "{\"age\":100,\"name\":\"Tester\"}".parseObject()
        XCTAssertEqual(dict2, [:])
    }

    func testToDictionary() {
        XCTAssertNil("".toDictionary())
        guard let dict = "{\"age\":100,\"name\":\"Tester\"}".toDictionary() else {
            XCTFail("Shouldn't be nil")
            return
        }
        XCTAssertEqual(dict["name"] as? String, "Tester")
        XCTAssertEqual(dict["age"] as? Int, 100)
    }

    func testCommaSeparatedListShouldJoinWithComma() {
        XCTAssertEqual(["foo", "bar"].asCommaSeparatedList(trailingSpace: false), "foo,bar")
    }

    func testCommaSeparatedListShouldJoinWithCommaWithTrailingSpaceIfParameterTrue() {
        XCTAssertEqual(["foo", "bar"].asCommaSeparatedList(trailingSpace: true), "foo, bar")
    }

    func testCommaSeparatedListShouldIgnoreEmptyStringElementsWhenSingleValue() {
        XCTAssertEqual(["", "foo"].asCommaSeparatedList(trailingSpace: true), "foo")
    }

    func testCommaSeparatedListShouldIgnoreEmptyStringElements() {
        XCTAssertEqual(["", "foo", "", "bar"].asCommaSeparatedList(trailingSpace: true), "foo, bar")
    }
}

extension String_ExtensionTests {
    func testSubscript() {
        let str = "abcd"
        let character: Character = str[0]
        XCTAssertEqual(character, "a" as Character)
        let string: String = str[1]
        XCTAssertEqual(string, "b")
    }

    func testGetDisplayAddress() {
        let data = """
        [
          {"Name": "Tester"},
          {"Address": "zzz@test.com"},
          {"Name": "Hi", "Address": "abc@test.com"}
        ]
        """
        let ans1 = [
            "Tester &lt;<a href=\"mailto:\" class=\"\"></a>&gt;",
            " &lt;<a href=\"mailto:zzz@test.com\" class=\"\">zzz@test.com</a>&gt;",
            "Hi &lt;<a href=\"mailto:abc@test.com\" class=\"\">abc@test.com</a>&gt;"
        ]
        let result1 = data.formatJsonContact(true)
        for ans in ans1 {
            XCTAssertTrue(result1.preg_match(ans))
        }

        let ans2 = [
            "Tester&lt;&gt;",
            "&lt;zzz@test.com&gt;",
            "Hi&lt;abc@test.com&gt;"
        ]
        let result2 = data.formatJsonContact(false)
        for ans in ans2 {
            XCTAssertTrue(result2.preg_match(ans))
        }
    }

    func testToContacts() {
        let data = """
        [
          {"Name": "Tester"},
          {"Address": "zzz@test.com"},
          {"Name": "Hi", "Address": "abc@test.com"}
        ]
        """
        let contacts = data.toContacts()
        for contact in contacts {
            if contact.name == "Tester" {
                XCTAssertEqual(contact.email, "")
            } else if contact.email == "zzz@test.com" {
                XCTAssertEqual(contact.name, "")
            } else {
                XCTAssertEqual(contact.name, "Hi")
                XCTAssertEqual(contact.email, "abc@test.com")
            }
        }
    }

    func testToContact() {
        var data = "{\"Name\": \"Tester\"}"
        XCTAssertNil(data.toContact())

        data = "{\"Address\": \"zzz@test.com\"}"
        var contact = data.toContact()
        XCTAssertEqual(contact?.name, "")
        XCTAssertEqual(contact?.email, "zzz@test.com")

        data = "{\"Name\": \"Hi\", \"Address\": \"abc@test.com\"}"
        contact = data.toContact()
        XCTAssertEqual(contact?.name, "Hi")
        XCTAssertEqual(contact?.email, "abc@test.com")
    }
}
