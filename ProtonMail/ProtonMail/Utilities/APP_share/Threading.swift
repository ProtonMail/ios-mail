//
//  Threading.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Dispatch
import UIKit

enum ThreadType {
    case main
    case async
}

/** Serial dispatch queue used by the ~> operator. */
private let async_q: DispatchQueue = DispatchQueue(label: "Async queue", attributes: DispatchQueue.Attributes.concurrent)

infix operator ~>

// TODO:: need add some ui handling, 
// like if some operation need to force user logout need ui to handle the response make sure not popup any unnecessary windows
func ~> (
    left: @escaping () -> Void,
    type: ThreadType) {
    switch type {
    case .main:
        OperationQueue.main.addOperation {
            left()
        }
    default:
        async_q.async(execute: {
            left()
        })
    }
}
