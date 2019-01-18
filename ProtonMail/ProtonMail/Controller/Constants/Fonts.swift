
//  Fonts.swift
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

//TODO:: move this to UI
enum Fonts : CGFloat {
    case h1 = 24.0
    /// size 18
    case h2 = 18.0
    case h3 = 17.0
    /// size 16
    case h4 = 16.0
    case h5 = 14.0
    /// size 12
    case h6 = 12.0
    case h7 = 9.0
    /// custom size
    case s20 = 20.0
    case s13 = 13.0
    
    var regular : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .regular)
    }
    
    var light : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .light)
    }
    
    var medium : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .medium)
    }
    
    var bold : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .bold)
    }
}


extension UIFont {
    static var highlightSearchTextForTitle: UIFont {
        return  Fonts.h2.bold
    }
    
    static var highlightSearchTextForSubtitle: UIFont {
        return  Fonts.h5.bold
    }
}
