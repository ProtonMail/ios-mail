//
//  MessagePrintRenderer.swift
//  Proton Mail - Created on 12/08/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import WebKit

/*
 This class is responsible for printing messages.

 Beside the HTML content taken from the webView, we also need to print a header view and an attachment view.

 We only want to print them on the first page, which is problematic from the standpoint of the API, which has been
 designed by Apple to include headers and footers on every page.

 Manual manipulation of printing rectangles has proved problematic, as the print formatters rescale their output -
 probably to avoid having to recalculate the distribution of content into pages.

 The trick we use is to add a top margin to the HTML body and draw the headers directly on top.
 */
class MessagePrintRenderer: UIPrintPageRenderer {
    private let customViewRenderers: [CustomViewPrintRenderer]

    init(webView: WKWebView, customViewRenderers: [CustomViewPrintRenderer]) {
        self.customViewRenderers = customViewRenderers

        super.init()

        let topOffset = customViewRenderers.map(\.contentSize.height).reduce(0, +)

        let cssString = "@media print { body { margin-top: \(topOffset)pt; } }"
        let jsString = """
var style = document.createElement('style');
style.innerHTML = '\(cssString)';
document.head.appendChild(style);
0
"""
        webView.configuration.preferences.javaScriptEnabled = true
        webView.evaluateJavaScript(jsString) { _, error in
            webView.configuration.preferences.javaScriptEnabled = false

            if let error = error {
                assertionFailure("\(error)")
            }
        }

        let printFormatter = webView.viewPrintFormatter()
        addPrintFormatter(printFormatter, startingAtPageAt: 0)
    }

    override func drawPrintFormatter(_ printFormatter: UIPrintFormatter, forPageAt pageIndex: Int) {
        super.drawPrintFormatter(printFormatter, forPageAt: pageIndex)

        if pageIndex == 0 {
            var workingRect = printableRect

            for customViewRenderer in customViewRenderers {
                let viewHeight = customViewRenderer.contentSize.height
                let (slice, remainder) = workingRect.divided(atDistance: viewHeight, from: .minYEdge)
                customViewRenderer.draw(in: slice)

                workingRect = remainder
            }
        }
    }
}

protocol CustomViewPrintable {
    func printPageRenderer() -> CustomViewPrintRenderer
    func printingWillStart(renderer: CustomViewPrintRenderer)
}
