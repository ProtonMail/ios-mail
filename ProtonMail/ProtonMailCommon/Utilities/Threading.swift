//
//  Threading.swift
//  ProtonMail
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
private let async_q : DispatchQueue = DispatchQueue(label: "Async queue", attributes: DispatchQueue.Attributes.concurrent)


infix operator ~>

///**
// Executes the lefthand closure on a background thread and,
// upon completion, the righthand closure on the main thread.
// Passes the background closure's output, if any, to the main closure.
// */
func ~> <R> (
    backgroundClosure: @escaping () -> R,
    mainClosure: @escaping (_ result: R) -> ())
{
    async_q.async(execute: {
        let result = backgroundClosure()
        OperationQueue.main.addOperation {
            mainClosure(result)
        }
    })
}

//TODO:: need add some ui handling, 
//like if some operation need to force user logout need ui to handle the response make sure not popup any unnecessary windows
func ~> (
    left: @escaping () -> Void,
    type: ThreadType)
{
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
