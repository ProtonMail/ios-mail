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
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func updateStatusButton () {
//        switch self.model.status {
//        case 0:
//            selectStatusButton.setImage(UIImage(named:"mail_check"), forState: UIControlState.Normal)
//            break
//        case 1:
//            selectStatusButton.setImage(UIImage(named:"mail_check-neutral"), forState: UIControlState.Normal)
//            break;
//        case 2:
//            selectStatusButton.setImage(UIImage(named:"mail_check-active"), forState: UIControlState.Normal)
//            break
//        default:
//            selectStatusButton.setImage(UIImage(named:"mail_check"), forState: UIControlState.Normal)
//            break
//        }
    }
    
    func ConfigCell(countryCode : CountryCode!, vc : UIViewController) {
        let image = UIImage(named: "flags.bundle/\(countryCode.country_code!)" )
        
        //imageView?.image = image
      //  imageView?.setImageWithURL(<#url: NSURL!#>, placeholderImage: <#UIImage!#>)
        
        countryLabel.text = countryCode.country_en
        
        codeLabel.text = "+ \(countryCode.phone_code ?? 1)"
        
        self.updateStatusButton()
    }
}
