//
//  UINavigationController+Extension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/21/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


extension UINavigationController {

    func firstViewController() -> UIViewController? {
        return self.viewControllers.first
    }
}

