//
//  CountryCodeTableViewCell.swift
//  ProtonMail - Created on 8/17/15.
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

class CountryCodeTableViewCell : UITableViewCell {
    
    @IBOutlet weak var flagImage: UIImageView! // no longer used, replaced by flag emoji in v1.11.12
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.contentMode = .scaleAspectFit
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func ConfigCell(_ countryCode : CountryCode, vc : UIViewController) {
        countryLabel.text = self.flag(countryCode.country_code) + " " + countryCode.country_en
        codeLabel.text = "+ \(countryCode.phone_code)"
    }
    
    private func flag(_ country:String) -> String {
        let base : UInt32 = 127397 // start of Unicode range of flags https://en.wikipedia.org/wiki/Regional_Indicator_Symbol
        var s = ""
        for v in country.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + v.value) {
                s.unicodeScalars.append(scalar)
            }
        }
        return s
    }
}
