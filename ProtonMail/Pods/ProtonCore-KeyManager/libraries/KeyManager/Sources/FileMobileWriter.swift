//
//  FileMobileWriter.swift
//  ProtonCore-KeyManager - Created on 07/08/2021.
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
import ProtonCoreCryptoGoInterface

@available(*, deprecated, message: "please to use ProtonCore-Crypto module FileMobileWriter")
class FileMobileWriter: NSObject, CryptoWriterProtocol {
    var file: FileHandle

    init(file: FileHandle) {
        self.file = file
    }

    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws {
        if b == nil {
            n?.pointee = 0
            return
        }
        self.file.write(b!)
        n?.pointee = b!.count
    }
}
