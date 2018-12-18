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
    var vc : UIViewController!;

    @IBOutlet weak var flagImage: UIImageView!
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
        var frame = imageView?.frame
        frame?.origin.x = 0
        frame?.size.width = 24
        imageView?.frame = frame!
    }
    
    func ConfigCell(_ countryCode : CountryCode!, vc : UIViewController) {
        let image = UIImage(named: "flags.bundle/\(countryCode.country_code)" )
        imageView?.image = image
        countryLabel.text = countryCode.country_en
        codeLabel.text = "+ \(countryCode.phone_code)"
    }
}
