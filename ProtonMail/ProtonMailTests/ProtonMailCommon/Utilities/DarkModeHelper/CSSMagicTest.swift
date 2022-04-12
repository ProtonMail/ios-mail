// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import SwiftSoup
import XCTest
@testable import ProtonMail



final class CSSMagicTest: XCTestCase {

    func testCanSupportDarkStyle() {
        let cache = DarkModeStatusStub()
        var level = CSSMagic.darkStyleSupportLevel(htmlString: "",
                                                   isNewsLetter: true,
                                                   isPlainText: false,
                                                   darkModeCache: cache)
        XCTAssertEqual(level, DarkStyleSupportLevel.notSupport)

        level = CSSMagic.darkStyleSupportLevel(htmlString: "",
                                               isNewsLetter: false,
                                               isPlainText: true,
                                               darkModeCache: cache)
        XCTAssertEqual(level, DarkStyleSupportLevel.protonSupport)

        level = CSSMagic.darkStyleSupportLevel(htmlString: "",
                                               isNewsLetter: true,
                                               isPlainText: true,
                                               darkModeCache: cache)
        XCTAssertEqual(level, DarkStyleSupportLevel.protonSupport)

        cache.darkModeStatus = .forceOff
        level = CSSMagic.darkStyleSupportLevel(htmlString: "",
                                               isNewsLetter: false,
                                               isPlainText: false,
                                               darkModeCache: cache)
        XCTAssertEqual(level, DarkStyleSupportLevel.notSupport)

        cache.darkModeStatus = .followSystem
        var htmls = [
            #"<html><head> <meta name="supported-color-schemes" content="[light? || dark? || <ident>?]* || only?"></head><body></body></html>"#,
            #"<html><head> <meta name="color-scheme" content="[light? || dark? || <ident>?]* || only?"></head><body></body></html>"#,
            "<html><head> <style>:root{color-scheme: light dark;}</style></head><body></body></html>",
        ]
        for html in htmls {
            let level = CSSMagic.darkStyleSupportLevel(htmlString: html,
                                                       isNewsLetter: false,
                                                       isPlainText: false,
                                                      darkModeCache: cache)
            XCTAssertEqual(level, DarkStyleSupportLevel.nativeSupport)
        }
        htmls = [
            "<html><head></head><body> <table> </table></body></html>",
            "<html><head></head><body> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> <div> hi </div></div></div></div></div></div></div></div></div></div></div></div></div></div></body></html>"
        ]
        for html in htmls {
            let level = CSSMagic.darkStyleSupportLevel(htmlString: html,
                                                       isNewsLetter: false,
                                                       isPlainText: false,
                                                      darkModeCache: cache)
            XCTAssertEqual(level, DarkStyleSupportLevel.notSupport)
        }
        htmls = [
            "<html><head></head><body> <span> a</span></body></html>",
        ]
        for html in htmls {
            let level = CSSMagic.darkStyleSupportLevel(htmlString: html,
                                                       isNewsLetter: false,
                                                       isPlainText: false,
                                                      darkModeCache: cache)
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
        css = CSSMagic.generateCSSForDarkMode(htmlString: html)
        expected = "div.a[style=\"background-color: hsl(0, 0%, 100%);\"] { background-color: hsla(230, 12%, 10%, 1.0) !important }"
        XCTAssertEqual(css, "@media (prefers-color-scheme: dark) { \(expected) }")

        html = """
        <html> </head> <body> <div style="font-family:&quot;Google Sans&quot;,Arial,sans-serif;font-weight:400 color: red"></div></body></html>
        """
        css = CSSMagic.generateCSSForDarkMode(htmlString: html)
        XCTAssertEqual(css, "@media (prefers-color-scheme: dark) {  }")

        html = """
        <html> <head> <style>span{background-color: rgb(51, 102, 153);}</style> </head> <body> <div class="a" style="color: white">a</div><span>abc</span> </body></html>
        """
        css = CSSMagic.generateCSSForDarkMode(htmlString: html)
        XCTAssertEqual(css, "@media (prefers-color-scheme: dark) { span { background-color: hsla(210, 50%, 30%, 1.0) !important }div.a[style=\"color: white\"] { color: hsla(0, 0%, 100%, 1.0) !important } }")
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

    func testGetStyleNodes() {
        let html = """
        <html> <head> <style>/*ignore me*/.a{color: #336699;/*ignore me*/}span{font-size: large;}</style> <style>span{background-color: rgb(51, 102, 153);}</style> </head> <body> <div class="a">a</div><span>abc</span> </body></html>
        """
        let document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        let styleCSS = CSSMagic.getStyleCSS(from: document!)
        let expected = [".a{color: #336699;}span{font-size: large;}",
                        "span{background-color: rgb(51, 102, 153);}"]
        XCTAssertEqual(styleCSS, expected)

        let newStyleCSS = CSSMagic.getDarkModeCSSDictFrom(styleCSS: styleCSS)
        let aSelector = newStyleCSS[".a"]
        XCTAssertNotNil(aSelector)
        XCTAssertEqual(aSelector, ["color: hsla(210, 50%, 60%, 1.0) !important"])
        let spanSelector = newStyleCSS["span"]
        XCTAssertNotNil("span")
        XCTAssertEqual(spanSelector, ["background-color: hsla(210, 50%, 30%, 1.0) !important"])
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

    func testGetDarkModeCSSDictForColorNodes() {
        var html = ""
        var nodes: [Element]
        var document: Document?
        var result: [String: [String]] = [:]
        var key = ""

        html = """
        <html> </head> <body> <div class="a" style="background-color: hsl(120, 30%, 40%); color: black;"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = CSSMagic.getDarkModeCSSDict(for: nodes)
        key = "div.a[style=\"background-color: hsl(120, 30%, 40%); color: black;\"]"
        XCTAssertEqual(Array(result.keys), [key])
        XCTAssertEqual(result[key]?.count, 2)

        html = """
        <html> </head> <body> <div style="font-family:&quot;Google Sans&quot;,Arial,sans-serif;font-weight:400 color: red"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = CSSMagic.getDarkModeCSSDict(for: nodes)
        XCTAssertEqual(Array(result.keys).count, 0)
    }

    func testGetDarkModeCSSFromNode() {
        var html = ""
        var document: Document?
        var nodes: [Element]
        var result: [String] = []

        html = """
        <html> </head> <body> <div class="a" color="blue" bgcolor="transparent" font="sans"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = CSSMagic.getDarkModeCSS(from: nodes[0])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], "color: hsla(240, 100%, 60%, 1.0) !important")

        html = """
        <html> </head> <body> <div style="color: black;"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = CSSMagic.getDarkModeCSS(from: nodes[0])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], "color: hsla(0, 0%, 100%, 1.0) !important")

        html = """
        <html> </head> <body> <div style="background-color: hsl(120, 30%, 40%);"></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        result = CSSMagic.getDarkModeCSS(from: nodes[0])
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
        XCTAssertEqual(result, "hsla(230, 12%, 10%, 1.0)")

        result = CSSMagic.getDarkModeColor(from: "whitdilfjele", isForeground: true)
        XCTAssertNil(result)

        result = CSSMagic.getDarkModeColor(from: "rgb(51, 102, 153)", isForeground: true)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(210, 50%, 60%, 1.0)")

        result = CSSMagic.getDarkModeColor(from: "rgba(51, 102, 153, 0.7)", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(210, 50%, 30%, 0.7)")

        result = CSSMagic.getDarkModeColor(from: "hsl(51, 100%, 53%)", isForeground: true)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(51, 100%, 60%, 1.0)")

        result = CSSMagic.getDarkModeColor(from: "hsla(51, 100%, 53%, 0.5)", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(51, 100%, 30%, 0.5)")

        result = CSSMagic.getDarkModeColor(from: "fff", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(230, 12%, 10%, 1.0)")

        result = CSSMagic.getDarkModeColor(from: "fff !important", isForeground: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hsla(230, 12%, 10%, 1.0)")
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
        XCTAssertEqual(result, "hsla(20, 50%, 70%, 1.0)")

        hsla = HSLA(h: 20, s: 50, l: 30, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: true)
        XCTAssertEqual(result, "hsla(20, 50%, 60%, 1.0)")

        hsla = HSLA(h: 20, s: 50, l: 3, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: false)
        XCTAssertEqual(result, "hsla(20, 50%, 3%, 1.0)")

        hsla = HSLA(h: 20, s: 50, l: 93, a: 1)
        result = CSSMagic.hslaForDarkMode(hsla: hsla, isForeground: false)
        XCTAssertEqual(result, "hsla(20, 50%, 30%, 1.0)")
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
        XCTAssertEqual(anchor, "div.a.b[bgcolor=\"red\"][env=\"test\"]")

        html = """
        <html> <head></head> <body> <div style="color: red;font-family: &quot;Google Sans&quot;, Arial, sans-serif" ></div></body></html>
        """
        document = CSSMagic.parse(htmlString: html)
        XCTAssertNotNil(document)
        nodes = CSSMagic.getColorNodes(from: document!)
        XCTAssertEqual(nodes.count, 1)
        anchor = CSSMagic.getCSSAnchor(of: nodes[0])
        XCTAssertEqual(anchor, "")
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

    func testGetMaxDepth() throws {
        let html = "<html><head></head><body> <div> <div> <div> hi </div></div></div><div> hi </div></body></html>"
        let document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            XCTFail("Should have body")
            return
        }
        XCTAssertEqual(body.getMaxDepth(), 5)
    }
}
