//
//  Threading.swift
//  ProtonMail
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
import Dispatch
import UIKit

enum MainThread {
    static func auto(_ block: @escaping (() -> Void)) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }

    }
}

enum ThreadType {
    case main
    case async
}

func main(_ left: @escaping () -> Void) {
    OperationQueue.main.addOperation {
        left()
    }
}

/** Serial dispatch queue used by the ~> operator. */
private let async_q: DispatchQueue = DispatchQueue(label: "Async queue", attributes: DispatchQueue.Attributes.concurrent)

infix operator ~>

/// **
// Executes the lefthand closure on a background thread and,
// upon completion, the righthand closure on the main thread.
// Passes the background closure's output, if any, to the main closure.
// */
func ~> <R> (
    backgroundClosure: @escaping () -> R,
    mainClosure: @escaping (_ result: R) -> Void) {
    async_q.async(execute: {
        let result = backgroundClosure()
        OperationQueue.main.addOperation {
            mainClosure(result)
        }
    })
}

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
