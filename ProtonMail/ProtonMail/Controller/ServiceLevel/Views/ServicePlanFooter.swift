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
    private var buttonAction: ((UIButton?)->Void)?
    
    override func prepareForInterfaceBuilder() {
        self.setupSubviews()
    }
    
    convenience init(title: NSAttributedString? = nil,
                     subTitle: String? = nil,
                     buttonTitle: NSAttributedString? = nil,
                     buttonEnabled: Bool = true,
                     buttonAction: ((UIButton?)->Void)?=nil)
    {
        self.init(frame: .zero)
        
        self.title.attributedText = title
        self.subtitle.text = subTitle
        
        if buttonTitle != nil {
            self.buyButton.setAttributedTitle(buttonTitle, for: .normal)
            self.buyButton.titleLabel?.numberOfLines = 0
            self.buyButton.titleLabel?.lineBreakMode = .byWordWrapping
            self.buyButton.titleLabel?.textAlignment = .center
            self.buttonAction = buttonAction
            self.buyButton.addTarget(self, action: #selector(self.performButtonAction), for: .touchUpInside)
            self.buyButton.isUserInteractionEnabled = buttonEnabled
        } else {
            self.buyButton.isHidden = true
        }
    }
    
    @objc private func performButtonAction() {
        self.buttonAction?(self.buyButton)
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
