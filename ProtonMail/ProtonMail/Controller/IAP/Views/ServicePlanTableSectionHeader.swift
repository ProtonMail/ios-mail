//
//  TableSectionHeader.swift
//  ProtonMail - Created on 19/08/2018.
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

class ServicePlanTableSectionHeader: UIView {
    @IBOutlet private weak var title: UILabel!
    
    convenience init(title: String, textAlignment: NSTextAlignment) {
        self.init(frame: .zero)
        defer {
            self.setup(title: title, textAlignment: textAlignment)
        }
    }
    
    func setup(title: String, textAlignment: NSTextAlignment) {
        self.title.text = title
        self.title.textAlignment = textAlignment
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    private func setupSubviews() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var textSize = self.title.textRect(forBounds: CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 20),
                                           limitedToNumberOfLines: 0)
        textSize = textSize.insetBy(dx: -20, dy: -20)
        return textSize.size
    }
}
