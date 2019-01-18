//
//  Snapshot.swift
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


import UIKit
import Foundation

class Snapshot {
    fileprivate struct Tag {
        static let snapshot = 101
    }
    
    fileprivate struct NibName {
        static let Name = "LaunchScreen"
    }
    
    private lazy var view: UIView = self.getFancyView() ?? self.getDefaultView()
    
    internal func show(at window: UIWindow) {
        window.addSubview(self.view)
        view.mas_makeConstraints { (make) -> Void in
            make?.top.equalTo()(window)
            make?.left.equalTo()(window)
            make?.right.equalTo()(window)
            make?.bottom.equalTo()(window)
        }
    }
    
    internal func remove() {
        self.view.removeFromSuperview()
    }
    
    private func getFancyView() -> UIView? {
        guard let view = Bundle.main.loadNibNamed(NibName.Name, owner: nil, options: nil)?.first as? UIView else {
            return nil
        }
        view.tag = Tag.snapshot
        return view
    }
    
    private func getDefaultView() -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ProtonMail.Blue_85B1DE
        view.tag = Tag.snapshot
        return view
    }
}
