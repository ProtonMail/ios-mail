//
//  NSMutableAttributedString+Extension.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/22.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

extension NSMutableAttributedString
{
    /**
     - parameters:
     - text: original string
     - search: search term to be highlighted in the string
     */
    class func highlightedString(text: String,
                                 search: String,
                                 font: UIFont) -> NSMutableAttributedString {
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
