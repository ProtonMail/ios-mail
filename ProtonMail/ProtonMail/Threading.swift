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
    case Main
    case Async
}

/** Serial dispatch queue used by the ~> operator. */
private let async_q : dispatch_queue_t = dispatch_queue_create("Async queue", DISPATCH_QUEUE_CONCURRENT)


infix operator ~> {}

///**
// Executes the lefthand closure on a background thread and,
// upon completion, the righthand closure on the main thread.
// Passes the background closure's output, if any, to the main closure.
// */
func ~> <R> (
    backgroundClosure: () -> R,
    mainClosure: (result: R) -> ())
{
    dispatch_async(async_q, {
        let result = backgroundClosure()
        NSOperationQueue.mainQueue().addOperationWithBlock {
            mainClosure(result: result)
        }
    })
}

//TODO:: need add some ui handling, 
//like if some operation need to force user logout need ui to handle the response make sure not popup any unnecessary windows
func ~> (
    left: () -> Void,
    type: ThreadType)
{
    switch type {
    case .Main:
        NSOperationQueue.mainQueue().addOperationWithBlock {
            left()
        }
    default:
        dispatch_async(async_q, {
            left()
        })
    }
}
