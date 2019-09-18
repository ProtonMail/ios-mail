//
//  HeaderedPrintRenderer.swift
//  ProtonMail - Created on 12/08/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

class HeaderedPrintRenderer: UIPrintPageRenderer {
    var header: CustomViewPrintRenderer?
    
    class CustomViewPrintRenderer: UIPrintPageRenderer {
        private(set) var view: UIView
        private(set) var contentSize: CGSize
        private var image: UIImage?
        
        func updateImage(in rect: CGRect) {
            self.contentSize = rect.size
            
            UIGraphicsBeginImageContextWithOptions(rect.size, true, 0.0)
            defer { UIGraphicsEndImageContext() }
            
            guard let context = UIGraphicsGetCurrentContext() else {
                self.image = nil
                return
            }
            self.view.layer.render(in: context)
            self.image = UIGraphicsGetImageFromCurrentImageContext()
        }
        
        init(_ view: UIView) {
            self.view = view
            self.contentSize = view.bounds.size
        }
        
        override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
            super.drawContentForPage(at: pageIndex, in: contentRect)
            guard pageIndex == 0 else { return }
            if let _ = UIGraphicsGetCurrentContext() {
                self.image?.draw(in: contentRect)
            }
        }
    }
    
    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        if pageIndex == 0, let headerHeight = self.header?.contentSize.height {
            let (shortRect, longRect) = contentRect.divided(atDistance: headerHeight, from: .minYEdge)
            self.header?.drawContentForPage(at: pageIndex, in: shortRect)
            super.drawContentForPage(at: pageIndex, in: longRect)
        } else {
            super.drawContentForPage(at: pageIndex, in: contentRect)
        }
    }
    
    override func drawPrintFormatter(_ printFormatter: UIPrintFormatter, forPageAt pageIndex: Int) {
        if pageIndex == 0 {
            printFormatter.perPageContentInsets = UIEdgeInsets(top: self.header?.contentSize.height ?? 0, left: 0, bottom: 0, right: 0)
            super.drawPrintFormatter(printFormatter, forPageAt: pageIndex)
            printFormatter.perPageContentInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            super.drawPrintFormatter(printFormatter, forPageAt: pageIndex)
        }
    }
}

@objc protocol Printable {
    func printPageRenderer() -> UIPrintPageRenderer
    @objc optional func printingWillStart(renderer: UIPrintPageRenderer)
    @objc optional func printingDidFinish()
}
