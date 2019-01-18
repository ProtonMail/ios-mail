//
//  CountryCode.swift
//  ProtonMail - Created on 3/30/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation


public class CountryCode {

    public var phone_code : Int = 0
    public var country_en : String = ""
    public var country_code : String = ""

    public func isValid() -> Bool {
        return phone_code > 0 && !country_en.isEmpty && !country_code.isEmpty
    }
    
    static public func getCountryCodes (_ content: [[String : Any]]!) -> [CountryCode]! {
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
    
    public func parseCountryCode (_ content: [String:Any]!) -> Bool {
        country_en = content["country_en"] as? String ?? ""
        country_code = content["country_code"] as? String ?? ""
        phone_code =  content["phone_code"] as? Int ?? 0
        
        return isValid()
    }
}
