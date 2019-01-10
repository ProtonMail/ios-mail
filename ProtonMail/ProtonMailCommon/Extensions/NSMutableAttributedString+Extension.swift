//
//  NSMutableAttributedString+Extension.swift
//  ProtonMail - Created on 2018/10/22.
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

extension NSAttributedString {
    /**
     - parameters:
     - text: original string
     - search: search term to be highlighted in the string
     */
    class func highlightedString(text: String,
                                 search: String,
                                 font: UIFont) -> NSAttributedString {
        let resultText = text
        let searchTerm = search
        let attributedString = NSMutableAttributedString(string: resultText)
        let pattern = "(\(searchTerm))"
        let range = NSMakeRange(0, resultText.count)
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        regex.enumerateMatches(
            in: resultText,
            options: NSRegularExpression.MatchingOptions(),
            range: range,
            using: { (textCheckingResult, matchingFlags, stop) -> Void in
                let subRange = textCheckingResult?.range
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                              value: UIColor.ProtonMail.Blue_6789AB,
                                              range: subRange!)
                
                attributedString.addAttribute(NSAttributedString.Key.font,
                                              value: font,
                                              range: subRange!)
        })
        
        return attributedString
    }
}
