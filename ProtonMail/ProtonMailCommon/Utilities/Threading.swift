//
//  Threading.swift
//  SwiftThreading
//
//  Created by Joshua Smith on 7/5/14.
//  Copyright (c) 2014 iJoshSmith. Licensed under the MIT License.
//
//
// This code has been tested against Xcode 6 Beta 5.
//
import Foundation
import Dispatch
import UIKit

enum ThreadType {
    case main
    case async
}

public func main(_ left: @escaping () -> Void) {
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
