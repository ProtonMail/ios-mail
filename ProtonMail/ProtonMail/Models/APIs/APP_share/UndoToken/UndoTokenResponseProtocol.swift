// Copyright (c) 2021 Proton AG
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

protocol UndoTokenResponseProtocol: AnyObject {
    var undoTokenData: UndoTokenData? { get set }
}

extension UndoTokenResponseProtocol {
    func parseUndoToken(response: [String: Any]) {
        guard let jsonObject = response["UndoToken"],
              let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                  return
              }
        // In order to use the APIService call with Result return type,
        // here needs to use the same decoding strategy as the Networking library.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .decapitaliseFirstLetter
        undoTokenData = try? decoder.decode(UndoTokenData.self, from: data)
    }
}
