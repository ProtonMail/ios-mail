//
//  DateUtils.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 12.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

extension Date {
 var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
