//
//  ServicePlanCapability.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ServicePlanCapability: UIView {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var serviceIcon: UIImageView!
    
    convenience init(image: UIImage? = nil,
                     title: String? = nil,
                     serviceIconVisible: Bool = false)
    {
        self.init(frame: .zero)
        if image != nil {
            self.icon.image = image
        } else {
            self.icon.isHidden = true
        }
        self.title.text = title
        self.serviceIcon.isHidden = !serviceIconVisible
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
        self.serviceIcon.tintColor = .gray
        self.serviceIcon.image = UIImage(named: "pin_code_confirm")?.withRenderingMode(.alwaysTemplate)
        self.icon.tintColor = UIColor.ProtonMail.ButtonBackground
    }
}
