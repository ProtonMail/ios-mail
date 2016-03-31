//
//  LabelTableViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class CountryCodeTableViewCell : UITableViewCell {
    var vc : UIViewController!;

    @IBOutlet weak var flagImage: UIImageView!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layoutMargins = UIEdgeInsetsZero;
        self.separatorInset = UIEdgeInsetsZero
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.contentMode = .ScaleAspectFit
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var frame = imageView?.frame
        print("\(frame)")
        frame?.origin.x = 0
        frame?.size.width = 24
        imageView?.frame = frame!
    }
    
    func ConfigCell(countryCode : CountryCode!, vc : UIViewController) {
        let image = UIImage(named: "flags.bundle/\(countryCode.country_code!)" )
        imageView?.image = image
        countryLabel.text = countryCode.country_en
        codeLabel.text = "+ \(countryCode.phone_code ?? 1)"
    }
}
