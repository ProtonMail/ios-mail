// Copyright (c) 2022 Proton Technologies AG
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

import LifetimeTracker
import UIKit
import WebKit

/*
 This class is responsible for printing conversation.

 Beside the HTML content taken from the webView, we also need to print a header view and an attachment view.

 We only want to print them on the first page of each message, which is problematic from the standpoint of the API, which has been
 designed by Apple to include headers and footers on every page.

 Manual manipulation of printing rectangles has proved problematic, as the print formatters rescale their output -
 probably to avoid having to recalculate the distribution of content into pages.

 The trick we use is to add a top margin to the HTML body and draw the headers directly on top.
 */
class ConversationPrintRenderer: UIPrintPageRenderer, LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    private let controllers: [SingleMessageContentViewController]
    private var conversationRenderers: [(WKWebView, [CustomViewPrintRenderer])] = []
    private var contentFormatters: [(UIViewPrintFormatter, [CustomViewPrintRenderer])] = []
    private var pagesHaveHeader: [Int: [CustomViewPrintRenderer]] = [:]
    private let elementClassName = "extra_space_for_print"

    init(_ controllers: [SingleMessageContentViewController]) {
        self.controllers = controllers
        super.init()
        conversationRenderers = controllers.compactMap { $0.createPrintingSources() }
        conversationRenderers
            .forEach { createPrintFormatters(from: $0) }
        addAllPrintFormatters()
        trackLifetime()
    }

    private func createPrintFormatters(from source: (WKWebView, [CustomViewPrintRenderer])) {
        let pageMargin: CGFloat = 40
        let messageMargin: CGFloat = 16
        let topOffset = source.1.map(\.contentSize.height).reduce(0, +) + pageMargin + messageMargin

        let element = "a\(String.randomString(7))a"
        let jsString = """
        resetContentSize();
        let \(element) = document.createElement('div');
        \(element).classList.add('\(elementClassName)')
        \(element).style = 'width: 100vw; height: \(topOffset)px'
        document.body.insertBefore(\(element), document.body.firstChild);
        0
        """

        let webView = source.0
        webView.evaluateJavaScript(jsString) { _, error in
            if let error = error {
                assertionFailure("\(error)")
            }
        }

        let contentFormatter = webView.viewPrintFormatter()
        contentFormatters.append((contentFormatter, source.1))
    }

    private func addAllPrintFormatters() {
        var indexOfHeader: [Int] = []
        var currentPage = 0
        for index in 0 ..< contentFormatters.count {
            let formatter = contentFormatters[index].0
            indexOfHeader.append(currentPage)
            addPrintFormatter(formatter, startingAtPageAt: currentPage)
            currentPage += 1
        }
    }

    override var numberOfPages: Int {
        var startPage = 0
        for contentFormatter in contentFormatters {
            let formatter = contentFormatter.0
            formatter.maximumContentWidth = printableRect.self.width
            formatter.maximumContentHeight = printableRect.self.height
            let work = {
                formatter.startPage = startPage
                self.pagesHaveHeader[startPage] = contentFormatter.1
                startPage = formatter.startPage + formatter.pageCount
            }
            if Thread.isMainThread {
                work()
            } else {
                DispatchQueue.main.async { work() }
            }
        }
        return super.numberOfPages
    }

    override func drawPrintFormatter(_ printFormatter: UIPrintFormatter, forPageAt pageIndex: Int) {
        super.drawPrintFormatter(printFormatter, forPageAt: pageIndex)

        if let headerRenderers = pagesHaveHeader[pageIndex] {
            let workingRect = printableRect

            var headerHeight: Double = 0.0
            if let headerRenderer = headerRenderers.first {
                headerHeight = headerRenderer.contentSize.height
                let (headerSlice, _) = workingRect.divided(atDistance: headerHeight, from: .minYEdge)
                headerRenderer.draw(in: headerSlice)

                if let attachmentRenderer = headerRenderers[safe: 1] {
                    let attachmentHeight = attachmentRenderer.contentSize.height
                    let (slice, _) = workingRect.divided(atDistance: attachmentHeight + headerHeight, from: .minYEdge)
                    let (attachmentSlice, _) = slice.divided(atDistance: attachmentHeight, from: .maxYEdge)
                    attachmentRenderer.draw(in: attachmentSlice)
                }
            }
        }
        revertChange(for: pageIndex)
    }

    // The webView is the same instance we saw in message body
    // Any change we did above will affect it
    // Revert change after we draw the page
    private func revertChange(for pageIndex: Int) {
        DispatchQueue.main.async {
            guard let renderer = self.conversationRenderers[safe: pageIndex] else { return }
            let jsString = """
        document.querySelectorAll('.\(self.elementClassName)').forEach(e=>e.remove())
        0
        """
            let webView = renderer.0
            webView.evaluateJavaScript(jsString) { _, error in
                if let error = error {
                    assertionFailure("\(error)")
                }
            }

            guard let controller = self.controllers[safe: pageIndex] else { return }
            controller.messageBodyViewController.updateDynamicFontSize()
        }
    }
}
