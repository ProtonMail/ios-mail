//
//  ServicePlanFooter.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ServicePlanFooter: UIView {

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var buyButton: UIButton!
    @IBOutlet private weak var subtitle: UILabel!
    
    override func prepareForInterfaceBuilder() {
        self.setupSubviews()
    }
    
    convenience init(title: String? = nil,
                     subTitle: String? = nil,
                     buttonTitle: String? = nil)
    {
        self.init(frame: .zero)
        
        self.title.text = title
        self.subtitle.text = subTitle
        
        if buttonTitle != nil {
            self.buyButton.setTitle(buttonTitle, for: .normal)
        } else {
            self.buyButton.isHidden = true
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
        
        self.buyButton.roundCorners()
        self.buyButton.backgroundColor = UIColor.ProtonMail.ButtonBackground
    }
}
