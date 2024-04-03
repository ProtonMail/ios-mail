//
//  Parser.swift
//  ProtonCore-QuarkCommands - Created on 08.12.2023.
//
// Copyright (c) 2023. Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCoreLog

public func parseQuarkCommandJsonResponse<T: Decodable>(jsonData: Data, type: T.Type) throws -> T? {
    let decoder = JSONDecoder()
    PMLog.info("jsonData: \(String(data: jsonData, encoding: .utf8) ?? "")")

    do {
        let response = try decoder.decode(type, from: jsonData)

        return response
    } catch let error as DecodingError {
        switch error {
        case .dataCorrupted(let context):
            throw ParseError(message: "Data corrupted: \(context.debugDescription), \(context.codingPath)")
        case .keyNotFound(let key, let context):
            throw ParseError(message: "Key not found: \(key), \(context.debugDescription), \(context.codingPath)")
        case .typeMismatch(let type, let context):
            throw ParseError(message: "Type mismatch: \(type), \(context.debugDescription), \(context.codingPath)")
        case .valueNotFound(let type, let context):
            throw ParseError(message: "Value not found: \(type), \(context.debugDescription), \(context.codingPath)")
        default:
            throw ParseError(message: "Decoding error: \(error)")
        }
    }
}

public func makeQuarkCommandTextToJson(data: Data) throws -> Data? {
    let inputString = String(data: data, encoding: .utf8)
    guard let lines = inputString?.split(separator: "\n") else {
       return nil
    }

    var jsonObject = [String: String]()

    for line in lines {
        let components = line.split(separator: ":", maxSplits: 1)
        if components.count == 2 {
            let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            jsonObject[key] = value
        }
    }

    return try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
}

public struct QuarkError: Error, LocalizedError {
    let urlResponse: URLResponse
    let message: String

    public var errorDescription: String? {
        """
        url: \(urlResponse)
        message: \(message)
        """
    }
}

public struct ParseError: Error, LocalizedError {
    let message: String

    public var errorDescription: String? {
        """
        \(message)
        """
    }
}
