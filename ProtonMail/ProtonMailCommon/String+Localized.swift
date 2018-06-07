//
//  String+Localized.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 05/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
