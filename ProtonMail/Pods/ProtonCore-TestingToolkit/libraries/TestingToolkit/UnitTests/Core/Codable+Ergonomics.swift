//
//  Codable+Ergonomics.swift
//  ProtonCore-TestingToolkit - Created on 08/09/2021.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Utilities

public extension Encodable {
    var toJsonDict: [String: Any] {
        try! JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as! [String: Any]
    }

    var toSuccessfulResponse: [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .custom({ codingPath in
            let lastKey = codingPath.last!
            if lastKey.intValue != nil {
                return lastKey
            }
            var exceptionKey: String?
            encodingStrategyExceptions.forEach {
                if lastKey.stringValue == $0.key {
                    exceptionKey = $0.value
                }
            }
            if let exceptionKey = exceptionKey {
                return CustomCodingKey(stringValue: exceptionKey)!
            }
            let firstLetter = lastKey.stringValue.prefix(1).uppercased()
            let modifiedKey = firstLetter + lastKey.stringValue.dropFirst()
            return CustomCodingKey(stringValue: modifiedKey)!
        })

        var result = try! JSONSerialization.jsonObject(with: encoder.encode(self)) as! [String: Any]
        result["Code"] = 1000
        return result
    }
    
    func toErrorResponse(code: Int, error: String) -> [String: Any] {
        var result = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as! [String: Any]
        result["Code"] = code
        result["Error"] = error
        return result
    }
    
    var encodingStrategyExceptions: [String: String] {
        return ["srpSession": "SRPSession"]
    }

    func toSuccessfulResponse(underKey key: String) -> [String: Any] {
        var result: [String: Any] = [:]
        result[key] = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(self))
        result["Code"] = 1000
        return result
    }
}

public extension Decodable {

    static func from(_ dict: [String: Any]?) -> Self {
        try! JSONDecoder.decapitalisingFirstLetter.decode(Self.self, from: JSONSerialization.data(withJSONObject: dict!))
    }
    
    static func fromIfPossible(_ dict: [String: Any]?) -> Self? {
        try? JSONDecoder.decapitalisingFirstLetter.decode(Self.self, from: JSONSerialization.data(withJSONObject: dict!))
    }
}

struct CustomCodingKey: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int? {
        return nil
    }
    
    init?(intValue: Int) {
        return nil
    }
}

extension Dictionary where Key == String, Value == Any {
    
    public func serializedToData() throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: .sortedKeys)
    }
    
}
