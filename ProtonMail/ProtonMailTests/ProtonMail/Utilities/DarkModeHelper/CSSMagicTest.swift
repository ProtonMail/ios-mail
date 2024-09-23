// Copyright (c) 2021 Proton AG
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

import SwiftSoup
import XCTest
@testable import ProtonMail

final class CSSMagicTest: XCTestCase {

    func testCanSupportDarkStyle() {
        let document = CSSMagic.parse(htmlString: "")
        var level = CSSMagic.darkStyleSupportLevel(document: document, sender: "", darkModeStatus: .followSystem)
        XCTAssertEqual(level, DarkStyleSupportLevel.protonSupport)

        level = CSSMagic.darkStyleSupportLevel(document: document, sender: "", darkModeStatus: .forceOff)
        XCTAssertEqual(level, DarkStyleSupportLevel.notSupport)

        var htmls = [
            #"<html><head> <meta name="supported-color-schemes" content="[light? || dark? || <ident>?]* || only?"></head><body></body></html>"#,
            #"<html><head> <meta name="color-scheme" content="[light? || dark? || <ident>?]* || only?"></head><body></body></html>"#,
            "<html><head> <style>:root{color-scheme: light dark;}</style></head><body></body></html>",
        ]
        for html in htmls {
            let document = CSSMagic.parse(htmlString: html)
            let level = CSSMagic.darkStyleSupportLevel(document: document, sender: "", darkModeStatus: .followSystem)
            XCTAssertEqual(level, DarkStyleSupportLevel.nativeSupport)
        }
        htmls = [
            "<html><head></head><body> <table> </table></body></html>",
            "<html><head></head><body> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> hi </div></div></div></div></div></div></div></div></div></div></div></div></div></div></body></html>",
            "<html><head></head><body> <span> a</span></body></html>",
        ]
        for html in htmls {
            let document = CSSMagic.parse(htmlString: html)
            let level = CSSMagic.darkStyleSupportLevel(document: document, sender: "", darkModeStatus: .followSystem)
            XCTAssertEqual(level, DarkStyleSupportLevel.protonSupport)
        }

        htmls = [
            #"<html><head> <meta name="supported-color-schemes" content="[light? || dark? || <ident>?]* || only?"></head><body></body></html>"#
        ]
        for html in htmls {
            let document = CSSMagic.parse(htmlString: html)
            let level = CSSMagic.darkStyleSupportLevel(document: document, sender: "test@pm.me", darkModeStatus: .followSystem)
            XCTAssertEqual(level, DarkStyleSupportLevel.protonSupport)
        }
    }

    func testGenerateCSSForDarkMode() {
        var html = ""
        var css = ""
        var expected = ""

        html = """
        <html> </head> <body> <div class="a" style="background-color: hsl(0, 0%, 100%);"></div></body></html>
        """
        var document = CSSMagic.parse(htmlString: html)
        css = CSSMagic.generateCSSForDarkMode(document: document)
        expected = "div.a[style*=\"background-color: hsl(0, 0%, 100%)\"] { background-color: #1C1B24 !important }"
        XCTAssertEqual(css, "@media (prefers-color-scheme: dark) { \(expected) }")

        html = """
        <html> </head> <body> <div style="font-family:&quot;Google Sans&quot;,Arial,sans-serif;font-weight:400 color: red"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        css = CSSMagic.generateCSSForDarkMode(document: document)
        XCTAssertEqual(css, "@media (prefers-color-scheme: dark) {  }")

        html = """
        <html> <head> <style>span{background-color: rgb(151, 202, 133);}</style> </head> <body> <div class="a" style="color: black;">a</div><span>abc</span> </body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        css = CSSMagic.generateCSSForDarkMode(document: document)
        expected = "@media (prefers-color-scheme: dark) { span {background-color: hsla(104, 39%, 30%, 1.0) !important;}div.a[style*=\"color: black\"] { color: hsla(0, 0%, 100%, 1.0) !important } }"
        XCTAssertEqual(css, expected)
    }

    func testColorContrast() {
        var html = ""
        var css = ""
        var expected = ""

        html = """
        <html> </head> <body> <div class="a" style="background-color: black; color: black"></div></body></html>
        """
        var document = CSSMagic.parse(htmlString: html)
        css = CSSMagic.generateCSSForDarkMode(document: document)
        XCTAssertEqual(css, "@media (prefers-color-scheme: dark) { div.a[style*=\"background-color: black\"][style*=\"color: black\"] { background-color: hsla(230, 12%, 10%, 1.0) !important;color: hsla(0, 0%, 100%, 1.0) !important } }")

        html = """
        <html> </head> <body> <div class="a" style="background-color: black"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        css = CSSMagic.generateCSSForDarkMode(document: document)
        XCTAssertEqual(css, "@media (prefers-color-scheme: dark) { div.a[style*=\"background-color: black\"] { background-color: hsla(230, 12%, 10%, 1.0) !important } }")

        html = """
        <html> </head> <body> <div class="a" style="background-color: white"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        css = CSSMagic.generateCSSForDarkMode(document: document)
        expected = "@media (prefers-color-scheme: dark) { div.a[style*=\"background-color: white\"] { background-color: #1C1B24 !important } }"
        XCTAssertEqual(css, expected)
    }
}

extension CSSMagicTest {
    func testParseHTML() {
        let html = """
        <html> <head></head> <body> <div class="a" style="background-color: red"> <div class="b"> <div class="c"> <span style="color: aqua">HI</span> </div></div></div></body></html>
        """
        let document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
    }

    func testGetStyleNodes() throws {
        var html = """
        <html> <head> <style>/*ignore me*/.a{color: #336635;/*ignore me*/}span{font-size: large;}</style> <style>span{background-color: rgb(151, 202, 153);}</style> </head> <body> <div class="a">a</div><span>abc</span> </body></html>
        """
        var document = try XCTUnwrap(CSSMagic.parse(htmlString: html))
        var styleCSS = CSSMagic.getStyleCSS(from: document)
        var expected = [".a{color: #336635;}span{font-size: large;}",
                        "span{background-color: rgb(151, 202, 153);}"]
        XCTAssertEqual(styleCSS, expected)

        var newStyleCSS = CSSMagic.getDarkModeCSSFrom(styleCSS: styleCSS)
        var expectedCSS = ".a {color: hsla(122, 33%, 90%, 1.0) !important;}span {background-color: hsla(122, 32%, 30%, 1.0) !important;}"
        XCTAssertEqual(newStyleCSS, expectedCSS)

        html = """
        <html><head><style>.email{background-color:#ffffff}</style><style>.email{width:100px}</style></head><body></body></html>
        """
        document = try XCTUnwrap(CSSMagic.parse(htmlString: html))
        styleCSS = CSSMagic.getStyleCSS(from: document)
        expected = [
            ".email{background-color:#ffffff}",
            ".email{width:100px}"
        ]
        XCTAssertEqual(styleCSS, expected)
        newStyleCSS = CSSMagic.getDarkModeCSSFrom(styleCSS: styleCSS)
        expectedCSS = ".email {background-color: #1C1B24 !important;}"
        XCTAssertEqual(newStyleCSS, expectedCSS)

        html = """
        <html>
            <head>
                <style>
                    #content,
                    .mailbody {
                        background-color: #ffffff;
                    }
                    .a .b {
                        background-color: #336635;
                    }
                </style>
            </head>
        </html>
        """
        document = try XCTUnwrap(CSSMagic.parse(htmlString: html))
        styleCSS = CSSMagic.getStyleCSS(from: document)
        expected = [
            "#content,\n            .mailbody {\n                background-color: #ffffff;\n            }\n            .a .b {\n                background-color: #336635;\n            }"
        ]
        XCTAssertEqual(styleCSS, expected)
        newStyleCSS = CSSMagic.getDarkModeCSSFrom(styleCSS: styleCSS)
        expectedCSS = "#content,.mailbody {background-color: #1C1B24 !important;}.a .b {background-color: hsla(122, 33%, 30%, 1.0) !important;}"
        XCTAssertEqual(newStyleCSS, expectedCSS)
    }

    func testGetStyleNodes_part2() throws {
        let html = """
        <html>
        <head>
            <style>
                body,
                html,
                td {
                    font-family: "Helvetica Neue", Helvetica, Arial, Verdana, sans-serif; /* Font family */
                    color: rgb(31, 31, 31);/* Font color */
                }
            </style>
        </head>
        </html>
        """
        let document = try XCTUnwrap(CSSMagic.parse(htmlString: html))
        let styleCSS = CSSMagic.getStyleCSS(from: document)
        let expected = [
            "body,\n        html,\n        td {\n            font-family: \"Helvetica Neue\", Helvetica, Arial, Verdana, sans-serif; \n            color: rgb(31, 31, 31);\n        }"
        ]
        XCTAssertEqual(styleCSS, expected)
        let newStyleCSS = CSSMagic.getDarkModeCSSFrom(styleCSS: styleCSS)
        XCTAssertEqual(newStyleCSS, "body,html,td {color: hsla(0, 0%, 100%, 1.0) !important;}")
    }

    func testGetColorNodes() {
        var html = ""
        var document: Document?
        var nodes: [SwiftSoup.Element] = []
        html = """
        <html> <head></head> <body> <div class="a" style="background-color: red"> <div class="b"> <div class="c"> <span style="color: aqua">HI</span> </div></div></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 2)

        html = """
        <html><head></head><body> <div class="a" style="background-color: aqua;"> <span>Hi</span> <font color="red">red text</font> </div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 2)
    }

    func testGetDarkModeCSSDictForColorNodes() throws {
        var html = ""
        var nodes: [Element]
        var document: Document?
        var result: [String: [String]] = [:]
        var key = ""

        html = """
        <html> </head> <body> <div class="a" style="background-color: hsl(120, 30%, 70%); color: black;"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = try XCTUnwrap(CSSMagic.getDarkModeCSSDict(for: nodes, startTime: Date().timeIntervalSinceReferenceDate), "Should have value")
        key = "div.a[style*=\"background-color: hsl(120, 30%, 70%)\"][style*=\"color: black\"]"
        XCTAssertEqual(Array(result.keys), [key])
        XCTAssertEqual(result[key]?.count, 2)

        html = """
        <html> </head> <body> <div style="font-family:&quot;Google Sans&quot;,Arial,sans-serif;font-weight:400 color: red"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = try XCTUnwrap(CSSMagic.getDarkModeCSSDict(for: nodes, startTime: Date().timeIntervalSinceReferenceDate), "Should have value")
        XCTAssertEqual(Array(result.keys).count, 0)

        html = """
        <html> </head> <body> <div style="height: auto; width: 100%; COLOR: aqua"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = try XCTUnwrap(CSSMagic.getDarkModeCSSDict(for: nodes, startTime: Date().timeIntervalSinceReferenceDate), "Should have value")
        XCTAssertEqual(Array(result.keys).count, 1)
        let value = try XCTUnwrap(result["div[style*=\"COLOR: aqua\"]"])
        XCTAssertEqual(value.first, "COLOR: hsla(180, 100%, 90%, 1.0) !important")
    }

    func testGetDarkModeCSSFromNode() throws {
        var html = ""
        var document: Document?
        var nodes: [Element]
        var result: [String] = []

        html = """
        <html> </head> <body> <div class="a" color="forestgreen" font="sans"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = try XCTUnwrap(CSSMagic.getDarkModeCSS(from: nodes[0]), "Should have value")
        XCTAssertEqual(result.count, 0)

        html = """
        <html> </head> <body> <div style="color: black;"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = try XCTUnwrap(CSSMagic.getDarkModeCSS(from: nodes[0]), "Should have value")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], "color: hsla(0, 0%, 100%, 1.0) !important")

        html = """
        <html> </head> <body> <div style="background-color: hsl(120, 30%, 70%);"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = try XCTUnwrap(CSSMagic.getDarkModeCSS(from: nodes[0]), "Should have value")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], "background-color: hsla(120, 30%, 30%, 1.0) !important")
    }

    func testGetDarkModeColorFromColor() {
        var result: String?

        result = CSSMagic.getDarkModeColor(from: "white", isForeground: true)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(0, 0%, 100%, 1.0)")

        result = CSSMagic.getDarkModeColor(from: "white", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "#1C1B24")

        result = CSSMagic.getDarkModeColor(from: "whitdilfjele", isForeground: true)
        XCTAssertNil(result)

        result = CSSMagic.getDarkModeColor(from: "rgb(51, 102, 153)", isForeground: true)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(210, 50%, 90%, 1.0)")

        result = CSSMagic.getDarkModeColor(from: "rgba(51, 102, 153, 0.7)", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(210, 50%, 30%, 0.7)")

        result = CSSMagic.getDarkModeColor(from: "hsl(51, 100%, 53%)", isForeground: true)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(51, 100%, 90%, 1.0)")

        result = CSSMagic.getDarkModeColor(from: "hsla(51, 100%, 53%, 0.5)", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(51, 100%, 30%, 0.5)")

        result = CSSMagic.getDarkModeColor(from: "fff", isForeground: false)
        XCTAssertEqual(result, "#1C1B24")

        result = CSSMagic.getDarkModeColor(from: "fff !important", isForeground: false)
        XCTAssertEqual(result, "#1C1B24")

        result = CSSMagic.getDarkModeColor(from: "#fff", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "#1C1B24")
    }
}

// MARK: Color parser
extension CSSMagicTest {
    func testGetRGBAFromHex() {
        var hex = ""
        var result: (CGFloat, CGFloat, CGFloat, CGFloat)?

        hex = "jifelfd"
        result = CSSMagic.getRGBA(from: hex)
        XCTAssertNil(result)

        hex = "idmeuf"
        result = CSSMagic.getRGBA(from: hex)
        XCTAssertNil(result)

        hex = "336699"
        result = CSSMagic.getRGBA(from: hex)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 1)

        hex = "#336699"
        result = CSSMagic.getRGBA(from: hex)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 1)

        hex = "#33669933"
        result = CSSMagic.getRGBA(from: hex)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 0.2)

        hex = "#3693"
        result = CSSMagic.getRGBA(from: hex)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 0.2)

        hex = "#369"
        result = CSSMagic.getRGBA(from: hex)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 1)
    }

    func testGetRGBAByRGB() {
        var rgb = ""
        var result: (CGFloat, CGFloat, CGFloat, CGFloat)?

        rgb = "rgb(51, 102, 153)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 1)

        rgb = "rgba(51, 102, 153, 0.5)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 0.5)

        rgb = "rgba(20%, 40%, 60%, 0.5)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 0.5)

        rgb = "rgba(20%, 40%, 60%, 70%)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 0.7)

        rgb = "rgb(20%, 40%, 60%)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 1)

        rgb = "rgba(20%, 40%, 60%, 255.65)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 1)

        rgb = "rgba(20%, 40%, 60%, 51)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 0.2)

        rgb = "rgba(20%, 40%, 60%, 1)"
        result = CSSMagic.getRGBA(by: rgb)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, 0.2)
        XCTAssertEqual(result?.1, 0.4)
        XCTAssertEqual(result?.2, 0.6)
        XCTAssertEqual(result?.3, 1)
    }

    func testGetHSLAFromRGBA() {
        var result = CSSMagic.getHSLA(from: 0.2, g: 0.4, b: 0.6, a: 0.5)
        XCTAssertEqual(result.h, 210)
        XCTAssertEqual(result.s, 50)
        XCTAssertEqual(result.l, 40)
        XCTAssertEqual(result.a, 0.5)

        result = CSSMagic.getHSLA(from: 0.2, g: 0.2, b: 0.2, a: 1)
        XCTAssertEqual(result.h, 0)
        XCTAssertEqual(result.s, 0)
        XCTAssertEqual(result.l, 20)
        XCTAssertEqual(result.a, 1)

        result = CSSMagic.getHSLA(from: 0.4, g: 0.2, b: 0.6, a: 0.3)
        XCTAssertEqual(result.h, 270)
        XCTAssertEqual(result.s, 50)
        XCTAssertEqual(result.l, 40)
        XCTAssertEqual(result.a, 0.3)

        result = CSSMagic.getHSLA(from: 0.4, g: 0.6, b: 0.2, a: 0.4)
        XCTAssertEqual(result.h, 90)
        XCTAssertEqual(result.s, 50)
        XCTAssertEqual(result.l, 40)
        XCTAssertEqual(result.a, 0.4)
    }

    func testGetHSLAFromHSLA() {
        var hsla = ""
        var result: HSLA?

        hsla = "hsl(100, 25%, 40%)"
        result = CSSMagic.getHSLA(from: hsla)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.h, 100)
        XCTAssertEqual(result?.s, 25)
        XCTAssertEqual(result?.l, 40)
        XCTAssertEqual(result?.a, 1)

        hsla = "hsla(100, 25%, 40%, 0.3)"
        result = CSSMagic.getHSLA(from: hsla)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.h, 100)
        XCTAssertEqual(result?.s, 25)
        XCTAssertEqual(result?.l, 40)
        XCTAssertEqual(result?.a, 0.3)

        hsla = "hsla(100, 25%, 40%, 50%)"
        result = CSSMagic.getHSLA(from: hsla)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.h, 100)
        XCTAssertEqual(result?.s, 25)
        XCTAssertEqual(result?.l, 40)
        XCTAssertEqual(result?.a, 0.5)

        hsla = "hsla(100, 25%, 40%, 255)"
        result = CSSMagic.getHSLA(from: hsla)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.h, 100)
        XCTAssertEqual(result?.s, 25)
        XCTAssertEqual(result?.l, 40)
        XCTAssertEqual(result?.a, 1)

        hsla = "hsla(100, 25%, 40%, 51)"
        result = CSSMagic.getHSLA(from: hsla)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.h, 100)
        XCTAssertEqual(result?.s, 25)
        XCTAssertEqual(result?.l, 40)
        XCTAssertEqual(result?.a, 0.2)

        hsla = "hsla(100, 25%, 40%, 1)"
        result = CSSMagic.getHSLA(from: hsla)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.h, 100)
        XCTAssertEqual(result?.s, 25)
        XCTAssertEqual(result?.l, 40)
        XCTAssertEqual(result?.a, 1)
    }

    func testHSLAForDarkMode() {
        var hsla: HSLA
        var result = ""

        hsla = HSLA(h: 0, s: 0, l: 50, a: 0.8)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: true)
        XCTAssertEqual(result, "hsla(0, 0%, 100%, 0.8)")

        hsla = HSLA(h: 0, s: 0, l: 50, a: 0.7)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: false)
        XCTAssertEqual(result, "hsla(230, 12%, 10%, 0.7)")

        hsla = HSLA(h: 20, s: 50, l: 70, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: true)
        XCTAssertEqual(result, "hsla(20, 50%, 90%, 1.0)")

        hsla = HSLA(h: 20, s: 50, l: 30, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: true)
        XCTAssertEqual(result, "hsla(20, 50%, 90%, 1.0)")

        hsla = HSLA(h: 20, s: 50, l: 3, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: false)
        XCTAssertEqual(result, "hsla(20, 50%, 3%, 1.0)")

        hsla = HSLA(h: 20, s: 50, l: 93, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: false)
        XCTAssertEqual(result, "hsla(20, 50%, 30%, 1.0)")

        hsla = HSLA(h: 0, s: 0, l: 100, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: false)
        XCTAssertEqual(result, "#1C1B24")
    }
}

// MARK: Test helper functions
extension CSSMagicTest {
    func testSplitFromCss() throws {
        var splits: [String]?
        var assemble = ""
        splits = CSSMagic.split(from: "rbga(100, 120, 30, 1)")
        XCTAssertNotNil(splits)
        XCTAssertEqual(splits?.count, 4)
        assemble = splits?.joined(separator: ",") ?? ""
        XCTAssertEqual(assemble, "100,120,30,1")

        splits = CSSMagic.split(from: "hsla(100, 20%, 30%, 0.5)")
        XCTAssertNotNil(splits)
        XCTAssertEqual(splits?.count, 4)
        assemble = splits?.joined(separator: ",") ?? ""
        XCTAssertEqual(assemble, "100,20%,30%,0.5")

        splits = CSSMagic.split(from: "hsl(100, 20%, 30%)")
        XCTAssertNotNil(splits)
        XCTAssertEqual(splits?.count, 3)
        assemble = splits?.joined(separator: ",") ?? ""
        XCTAssertEqual(assemble, "100,20%,30%")

        splits = CSSMagic.split(from: "rbg(10%, 20%, 30%)")
        XCTAssertNotNil(splits)
        XCTAssertEqual(splits?.count, 3)
        assemble = splits?.joined(separator: ",") ?? ""
        XCTAssertEqual(assemble, "10%,20%,30%")
    }

    func testNormalizeFloat() {
        var result: CGFloat? = 0
        result = CSSMagic.getNormalizeFloat(from: "50%")
        XCTAssertEqual(result, 0.5)

        result = CSSMagic.getNormalizeFloat(from: "10%")
        XCTAssertEqual(result, 0.1)

        result = CSSMagic.getNormalizeFloat(from: "32%")
        XCTAssertEqual(result, 0.32)

        result = CSSMagic.getNormalizeFloat(from: "10")
        XCTAssertNil(result)
    }

    func testNormalize() {
        var result: CGFloat?
        result = CSSMagic.normalize(value: "128", maximum: 255)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 128.0 / 255.0)

        result = CSSMagic.normalize(value: "20", maximum: 100)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 20.0 / 100.0)

        result = CSSMagic.normalize(value: "259", maximum: 100)
        XCTAssertEqual(result, 1.0)

        result = CSSMagic.normalize(value: "35%", maximum: 255)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 0.35)
    }

    func testSplitInlineAttributes() {
        let result = CSSMagic.splitInline(attributes: "font-family: arial; font-size: 14px;")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].key, "font-family")
        XCTAssertEqual(result[0].value, "arial")
        XCTAssertEqual(result[1].key, "font-size")
        XCTAssertEqual(result[1].value, "14px")
    }

    func testGetCSSAnchor() {
        var html = ""
        var document: Document!
        var nodes: [Element] = []
        var anchor = ""
        html = """
        <html> <head></head> <body> <div id="section" target="_blank" bgcolor="red" class="a b" env="test" style="font-family: &quot;Google Sans&quot;, Arial, sans-serif" ></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        anchor = CSSMagic.getCSSAnchor(of: nodes[0])
        XCTAssertEqual(anchor, "#section")

        html = """
        <html> <head></head> <body> <div id="email header" target="_blank" bgcolor="red" class="a b" env="test" style="font-family: &quot;Google Sans&quot;, Arial, sans-serif" ></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        anchor = CSSMagic.getCSSAnchor(of: nodes[0])
        XCTAssertEqual(anchor, "div[id='email header']")


        html = """
        <html> <head></head> <body> <div style="color: red;font-family: &quot;Google Sans&quot;, Arial, sans-serif" ></div><div>not me</div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        anchor = CSSMagic.getCSSAnchor(of: nodes[0])
        XCTAssertEqual(anchor, "html > body > div:nth-child(1)")

        html = """
        <html><body><div itemprop="description" style="color:#252525;padding:2px 0 0 0;font-size:12px;line-height:18px">....some contents</div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        anchor = CSSMagic.getCSSAnchor(of: nodes[0])
        XCTAssertEqual(anchor, "div[style*=\"color:#252525\"][style*=\"padding:2px 0 0 0\"]")

        html = """
        <html><body><div itemprop="description" style="color:#252525 !important;padding:2px 0 0 0;line-height:18px">....some contents</div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        anchor = CSSMagic.getCSSAnchor(of: nodes[0])
        XCTAssertEqual(anchor, "div[style*=\"color:#252525\"][style*=\"padding:2px 0 0 0\"]")
    }

    func testAssembleCSSDict() {
        var cssDict: [String: [String]] = [:]
        var css = ""
        cssDict = [
            "span": ["color: white"],
            "div": ["font: AAA"],
            "table": []
        ]
        // Dictionary doesn't have order, the order could different everytime
        let possible = ["span { color: white }div { font: AAA }",
                        "div { font: AAA }span { color: white }"]
        css = CSSMagic.assemble(cssDict: cssDict)
        if !possible.contains(css) {
            XCTFail("Failed")
        }
    }
}

// MARK: Test extension SwiftSoup.Element
extension CSSMagicTest {
    func testFlatChildNodes_case1() throws {
        let html = """
<html lang=><head></head><body> <div class="a"> <div class="b"> <div class="c"> <span>HI</span> </div></div></div></body></html>
"""
        let document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            XCTFail("Should have body")
            return
        }

        let nodes = body.flatChildNodes()
        XCTAssertEqual(nodes.count, 5)
    }

    func testFlatChildNodes_case2() throws {
        let html = """
        <!DOCTYPE><html><head></head><body> <div class="a" style="background-color: aqua;"> <span>Hi</span> <font color="red">red text</font> </div></body></html>
        """
        let document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            XCTFail("Should have body")
            return
        }

        let nodes = body.flatChildNodes()
        XCTAssertEqual(nodes.count, 4)
    }
}
