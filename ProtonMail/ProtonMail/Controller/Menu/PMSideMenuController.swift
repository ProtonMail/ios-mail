//
//  PMSideMenuController.swift
//  ProtonMail
//
//  Created  on 2021/10/14.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import SWRevealViewController
import UIKit

class PMSideMenuController: SWRevealViewController {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var childForStatusBarStyle: UIViewController? {
        if let nvc = self.frontViewController as? UINavigationController,
           let vc = nvc.firstViewController() {
            return vc
        }
        return self.rearViewController
    }
}
