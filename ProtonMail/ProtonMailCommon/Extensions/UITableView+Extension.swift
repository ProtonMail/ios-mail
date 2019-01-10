//
//  UITableView+Extension.swift
//  ProtonMail
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

extension UITableView {
    
    fileprivate struct Constant {
        static let animationDuration: TimeInterval = 1
    }
    
    func hideLoadingFooter(replaceWithView view: UIView? = UIView(frame: CGRect.zero)) {
        UIView.animate(withDuration: Constant.animationDuration, animations: { () -> Void in
            self.tableFooterView?.alpha = 0
            return
        }, completion: { (finished) -> Void in
            UIView.animate(withDuration: Constant.animationDuration, animations: { () -> Void in
                self.tableFooterView = view
            })
        })
    }
    func noSeparatorsBelowFooter() {
        tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func showLoadingFooter() {
        tableFooterView = LoadingView.viewForOwner(self)
        tableFooterView?.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
    }
    
    /**
     reset table view inset and margins to .zero
     **/
    func zeroMargin() {
        if (self.responds(to: #selector(setter: UITableViewCell.separatorInset))) {
            self.separatorInset = .zero
        }
        
        if (self.responds(to: #selector(setter: UIView.layoutMargins))) {
            self.layoutMargins = .zero
        }
    }
}



extension UITableView {
    
    func RegisterCell(_ cellID : String) {
        self.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
    }
}
