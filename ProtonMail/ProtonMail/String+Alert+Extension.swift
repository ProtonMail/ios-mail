//
//  String+Alert+Extension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


extension String {
    
    public func alertController() -> UIAlertController {
        let message = self
        return UIAlertController(title: LocalString._general_alert_title,
                                 message: message,
                                 preferredStyle: .alert)
    }
    
    public func alertController(_ localizedTitle : String) -> UIAlertController {
        let message = self
        return UIAlertController(title: localizedTitle,
                                 message: message,
                                 preferredStyle: .alert)
    }
}
