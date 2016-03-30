//
//  CountryCode.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/30/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


class CountryCode {

    var phone_code : Int?
    var country_en : String?
    var country_code : String?

    func isValid() -> Bool {
        if let pc = phone_code, let ce = country_en, let cc = country_code {
            return pc > 0 && !ce.isEmpty && !cc.isEmpty
        }
        
        return false
    }
    
    static func getCountryCodes (content: [Dictionary<String,AnyObject>]!) -> [CountryCode]! {
        var outList : [CountryCode] = [CountryCode]()
        
        for con in content {
            let out = CountryCode()
            out.parseCountryCode(con)
            if out.isValid() {
                outList.append(out)
            }
        }
        return outList
    }
    
    func parseCountryCode (content: Dictionary<String,AnyObject>!) -> Bool {
        country_en = content["country_en"] as? String
        country_code = content["country_code"] as? String
        phone_code =  content["phone_code"] as? Int
        
        return isValid()
    }
}
