//
//  VCardExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/1/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


extension PMNIVCard {
    func write() throws -> String? {
        var out_vcard : String?
        try ObjC.catchException {
            out_vcard = PMNIEzvcard.write(self)
        }
        return out_vcard
    }
}
