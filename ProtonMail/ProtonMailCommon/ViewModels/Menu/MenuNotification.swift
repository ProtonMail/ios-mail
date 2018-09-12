//
//  MenuObserver.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/11/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


extension Notification.Name {
    static var switchView: Notification.Name {
        return .init(rawValue: "MenuController.PushSwitchView")
    }
    static var forceUpgrade: Notification.Name {
        return .init(rawValue: "Application.ForceUpgrade")
    }
}
