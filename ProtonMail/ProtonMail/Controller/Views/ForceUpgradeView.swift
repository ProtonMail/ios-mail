//
//  ForceUpgradeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 09/11/18.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

protocol ForceUpgradeViewDelegate : AnyObject {
    func learnMore()
    func update()
}

class ForceUpgradeView : PMView {
    weak var delegate : ForceUpgradeViewDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    
    override func getNibName() -> String {
        return "ForceUpgradeView"
    }

    override func setup() {
        //set localized strings
        self.titleLabel.text = LocalString._update_required
        self.learnMoreButton.setTitle(LocalString._learn_more, for: .normal)
        self.updateButton.setTitle(LocalString._update_now, for: .normal)
    }

    @IBAction func updateAction(_ sender: AnyObject) {
        delegate?.update()
    }
    
    @IBAction func learnMoreAction(_ sender: AnyObject) {
        delegate?.learnMore()
    }
}

