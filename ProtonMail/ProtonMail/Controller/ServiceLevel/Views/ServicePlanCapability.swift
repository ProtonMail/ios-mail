//
//  ServicePlanCapability.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit


class ServicePlanCapability: UIView {
    internal private(set) var context: Any?
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var serviceIcon: UIImageView!
    
    convenience init(image: UIImage? = nil,
                     title: NSAttributedString? = nil,
                     serviceIconVisible: Bool = false,
                     context: Any? = nil)
    {
        self.init(frame: .zero)
        if image != nil {
            self.icon.image = image?.withRenderingMode(.alwaysTemplate)
        } else {
            self.icon.isHidden = true
        }
        self.title.attributedText = title
        self.serviceIcon.isHidden = !serviceIconVisible
        self.context = context
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
