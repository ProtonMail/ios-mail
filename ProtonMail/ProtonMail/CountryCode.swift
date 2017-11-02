//
//  CountryCode.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/30/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


public class CountryCode {

    public var phone_code : Int = 0
    public var country_en : String = ""
    public var country_code : String = ""

    public func isValid() -> Bool {
        return phone_code > 0 && !country_en.isEmpty && !country_code.isEmpty
    }
    
    static public func getCountryCodes (_ content: [Dictionary<String,Any>]!) -> [CountryCode]! {
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
    
    public func parseCountryCode (_ content: Dictionary<String,Any>!) -> Bool {
        country_en = content["country_en"] as? String ?? ""
        country_code = content["country_code"] as? String ?? ""
        phone_code =  content["phone_code"] as? Int ?? 0
        
        return isValid()
    }
}
