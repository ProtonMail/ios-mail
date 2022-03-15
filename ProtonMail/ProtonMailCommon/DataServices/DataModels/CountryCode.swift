//
//  CountryCode.swift
//  ProtonMail - Created on 3/30/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public class CountryCode {

    public var phone_code: Int = 0
    public var country_en: String = ""
    public var country_code: String = ""

    public func isValid() -> Bool {
        return phone_code > 0 && !country_en.isEmpty && !country_code.isEmpty
    }

    static public func getCountryCodes (_ content: [[String: Any]]!) -> [CountryCode]! {
        var outList: [CountryCode] = [CountryCode]()
        for con in content {
            let out = CountryCode()
            _ = out.parseCountryCode(con)
            if out.isValid() {
                outList.append(out)
            }
        }
        return outList
    }

    public func parseCountryCode (_ content: [String: Any]!) -> Bool {
        country_en = content["country_en"] as? String ?? ""
        country_code = content["country_code"] as? String ?? ""
        phone_code = content["phone_code"] as? Int ?? 0

        return isValid()
    }
}
