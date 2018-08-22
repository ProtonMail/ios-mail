//
//  Header.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ServicePlanHeader: UIView {
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var subtitle: UILabel!
    @IBOutlet private weak var subicon: UILabel!
    
    convenience init(image: UIImage? = nil,
                     title: String? = nil,
                     subicon: (String, UIColor)? = nil)
    {
        self.init(frame: .zero)
        self.icon.image = image
        self.subtitle.text = title
        
        if let subicon = subicon {
            self.subicon.text = subicon.0
            self.subicon.textColor = subicon.1
        } else {
            self.subicon.isHidden = true
        }
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
        self.icon.tintColor = UIColor.ProtonMail.ButtonBackground
    }
}
