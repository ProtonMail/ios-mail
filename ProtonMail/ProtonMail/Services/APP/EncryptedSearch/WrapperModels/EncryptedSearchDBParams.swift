// Copyright (c) 2022 Proton Technologies AG
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
import GoLibs

class EncryptedSearchDBParams: EncryptedsearchDBParams {
    /// The DB parameters that Crypto library needs.
    /// - Parameters:
    ///   - file: file path of the db
    ///   - table: name of the db table
    ///   - id: name of the message id filed
    ///   - time: name of the time field
    ///   - order: name of the order field
    ///   - labels: name of the labels field
    ///   - initVector: name of the iv field
    ///   - content: name of the content field
    ///   - contentFile: name of the contentFile field
    init?(
        _ file: String?,
        table: String?,
        id: String?,
        time: String?,
        order: String?,
        labels: String?,
        initVector: String?,
        content: String?,
        contentFile: String?
    ) {
        super.init(file,
                   table: table,
                   id_: id,
                   time: time,
                   order: order,
                   labels: labels,
                   initVector: initVector,
                   content: content,
                   contentFile: contentFile)
    }
}
