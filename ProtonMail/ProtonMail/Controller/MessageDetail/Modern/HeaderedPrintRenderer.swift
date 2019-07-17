//
//  HeaderedPrintRenderer.swift
//  ProtonMail - Created on 12/08/2019.
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
            printFormatter.perPageContentInsets = UIEdgeInsets(top: (self.header?.contentSize.height ?? 0) * 1.25, left: 0, bottom: 0, right: 0)
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
