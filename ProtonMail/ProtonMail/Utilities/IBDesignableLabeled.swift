//
//  IBDesignableCell.swift
//  ProtonMail - Created on 10/06/2018.
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

/// Calling method labelAtInterfaceBuilder() in prepareForInterfaceBuilder() of a concrete class will label cell with a class name in Interface Builder.
protocol IBDesignableLabeled: class {
    var contentView: UIView { get }
}
extension IBDesignableLabeled {
    internal func labelAtInterfaceBuilder() {
        let label = UILabel.init(frame: self.contentView.bounds)
        label.text = "\(Self.self)"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
        let colors: [UIColor] = [.magenta, .green, .blue, .yellow, .red]
        
        self.contentView.backgroundColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        self.contentView.addSubview(label)
    }
}
