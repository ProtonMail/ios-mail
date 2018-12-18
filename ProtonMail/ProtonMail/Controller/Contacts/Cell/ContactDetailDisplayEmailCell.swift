//
//  ContactDetailDisplayEmailCell.swift
//  ProtonMail - Created on 2018/10/10.
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

class ContactDetailDisplayEmailCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var iconStackView: UIStackView!
    
    func configCell(title: String, value: String, contactGroupColors: [String]) {        
        self.title.text = title
        self.value.text = value
        
        prepareContactGroupIcons(cell: self,
                                 contactGroupColors: contactGroupColors,
                                 iconStackView: iconStackView,
                                 showNoneLabel: false)
    }
}

extension ContactDetailDisplayEmailCell: ContactCellShare {} // use the default implementation
