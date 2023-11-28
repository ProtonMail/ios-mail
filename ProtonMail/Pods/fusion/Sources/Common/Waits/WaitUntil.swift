//
//  WaitUntil.swift
//  fusion
//
//  Created by Mateusz Szklarek on 03.04.23.
// 
//  The MIT License
//
//  Copyright (c) 2020 Proton Technologies AG
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

/**
 This method is an alternative for XCTNSPredicateExpectation & XCTWaiter. It uses custom run loop mechanism (based of CFRunLoopRunInMode) and it waits
 until condition is met.

 - parameter timeout: maximum waiting time for the condition
 - parameter condition: condition that has to be met to finish `waitUntil` execution before timeout
 - Returns: `Bool` which determines whether the condition is met or not
 */
@discardableResult
public func waitUntil(timeout: TimeInterval, condition: @autoclosure @escaping () -> Bool) -> Bool {
    RunLoop.runUntil(timeout: timeout, condition: condition)
}

private enum RunLoop {

    /// Run the current RunLoop until `condition` returns true, at most for `timeout` seconds.
    /// The `condition` will be called at intervals, and the RunLoop will be stopped as soon as it returns true.
    /// returns `true` if we exited because `condition` returned true, `false` because `timeout` expired.
    /// Based on a two blog posts:
    /// - https://pspdfkit.com/blog/2016/running-ui-tests-with-ludicrous-speed/
    /// - https://bou.io/CTTRunLoopRunUntil.html
    static func runUntil(timeout: TimeInterval, condition: @escaping () -> Bool) -> Bool {
        var fulfilled: Bool = false

        let beforeWaiting: (CFRunLoopObserver?, CFRunLoopActivity) -> Void = { _, _ in
            if fulfilled {
                return
            }

            fulfilled = condition()

            if fulfilled {
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        }
        let observer = CFRunLoopObserverCreateWithHandler(
            nil,
            CFRunLoopActivity.beforeWaiting.rawValue,
            true,
            0,
            beforeWaiting
        )

        CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, .defaultMode)
        CFRunLoopRunInMode(.defaultMode, timeout, false)
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, .defaultMode)

        /*
         If we haven't fulfilled the condition yet, test one more time before returning. This avoids
         that we fail the test just because we somehow failed to properly poll the condition, e.g. if
         the run loop didn't wake up.
         */
        if !fulfilled {
            fulfilled = condition()
        }

        return fulfilled
    }

}
