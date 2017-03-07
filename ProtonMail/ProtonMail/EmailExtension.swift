//
//  EmailExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/15/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



extension Email {
    func log() {
        PMLog.D("EmailID: \(self.emailID)")
        print("ContactID: \(self.contactID)")
        print("Email: \(self.email)")
        print("Name: \(self.name)")
        //print("Encrypt: \(self.encrypt)")
        print("Order: \(self.order)")
        print("Type: \(self.type)")
    }
    
    func emailType() -> String {
//        let pasred = type.parseJson();
        return type;
    }
}


//Extension::Array - Email
extension Array where Element: Email {
    func order() -> [Email] {
        return self.sorted { $0.order.compare($1.order) == .orderedAscending }
    }
}
