// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreNetworking

protocol FilePersistable {
    static var pathComponent: String { get }
}

extension AuthCredential: FilePersistable {
    static var pathComponent: String {
        "AuthCredential.data"
    }
}

extension UserInfo: FilePersistable {
    static var pathComponent: String {
        "UserInfo.data"
    }
}

extension Array: FilePersistable where Element: FilePersistable {
    static var pathComponent: String {
        "ArrayOf\(Element.pathComponent)"
    }
}

struct UserObjectsPersistence {
    private let directoryURL: URL

    static let shared = UserObjectsPersistence()

    init(directoryURL: URL = FileManager.default.documentDirectoryURL) {
        self.directoryURL = directoryURL
    }

    func write<T: Encodable & FilePersistable>(_ object: T, key: MainKey) throws {
        do {
            let encodedData = try JSONEncoder().encode(object)
            let encryptedData = try Locked<Data>(clearValue: encodedData, with: key)
            let fileURL = directoryURL.appendingPathComponent(T.pathComponent)
            try encryptedData.encryptedValue.write(to: fileURL)
        } catch {
            Analytics.shared.sendError(.userObjectsJsonEncodingError(error, Mirror(reflecting: object).description))
            throw error
        }
    }

    func read<T: Decodable & FilePersistable>(_ type: T.Type, key: MainKey) throws -> T {
        do {
            let fileURL = directoryURL.appendingPathComponent(T.pathComponent)
            let encryptedData = try Data(contentsOf: fileURL)
            let decryptedData = try Locked<Data>(encryptedValue: encryptedData).unlock(with: key)
            let decodedObject = try JSONDecoder().decode(type, from: decryptedData)
            return decodedObject
        } catch {
            Analytics.shared.sendError(.userObjectsJsonDecodingError(error, Mirror(reflecting: T.self).description))
            throw error
        }
    }

    func cleanAll() {
        let pathComponents = [
            AuthCredential.pathComponent,
            UserInfo.pathComponent,
            [AuthCredential].pathComponent,
            [UserInfo].pathComponent
        ]
        let urls = pathComponents.map { directoryURL.appendingPathComponent($0) }
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
