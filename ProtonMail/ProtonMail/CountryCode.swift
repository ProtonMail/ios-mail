//
//  CountryCode.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/30/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


class CountryCode {

    var phone_code : Int = 0
    var country_en : String = ""
    var country_code : String = ""

    func isValid() -> Bool {
        return phone_code > 0 && !country_en.isEmpty && !country_code.isEmpty
    }
    
    static func getCountryCodes (_ content: [Dictionary<String,AnyObject>]!) -> [CountryCode]! {
        var outList : [CountryCode] = [CountryCode]()
        
        for con in content {
            let out = CountryCode()
            let _ = out.parseCountryCode(con)
            if out.isValid() {
                outList.append(out)
            }
        }
        return outList
    }
    
    func parseCountryCode (_ content: Dictionary<String,AnyObject>!) -> Bool {
        country_en = content["country_en"] as? String ?? ""
        country_code = content["country_code"] as? String ?? ""
        phone_code =  content["phone_code"] as? Int ?? 0
        
        return isValid()
    }
}
