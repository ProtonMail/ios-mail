//
//  UIApplication+BadgeNumber.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/26/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

extension UIApplication {
    class func setBadge(badge:Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = badge
        }
    }
}

