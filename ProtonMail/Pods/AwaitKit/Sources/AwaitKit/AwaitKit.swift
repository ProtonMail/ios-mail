/*
 * AwaitKit
 *
 * Copyright 2016-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import Foundation
import PromiseKit
import Dispatch

/// Convenience struct to make the background job.
public struct Queue {
  static let async = DispatchQueue(label: "com.yannickloriot.asyncqueue", attributes: .concurrent)
  static let await = DispatchQueue(label: "com.yannickloriot.awaitqueue", attributes: .concurrent)
}

/**
 Yields the execution to the given closure and returns a new promise.
 - parameter body: The closure that is executed on a concurrent queue.
 - returns: A new promise that is resolved when the provided closure returned.
 */
public func async<T>(_ body: @escaping () throws -> T) -> Promise<T> {
  return Queue.async.async(.promise, execute: body)
}

/**
 Yields the execution to the given closure which returns nothing.
 - parameter body: The closure that is executed on a concurrent queue.
 */
public func async(_ body: @escaping () throws -> Void) {
  Queue.async.ak.async(body)
}

/**
 Awaits that the given closure finished and returns its value or throws an error if the closure failed.
 - parameter body: The closure that is executed on a concurrent queue.
 - throws: The error sent by the closure.
 - returns: The value of the closure when it is done.
 */
@discardableResult
public func await<T>(_ body: @escaping () throws -> T) throws -> T {
  return try Queue.await.ak.await(body)
}

/**
 Awaits that the given promise resolved and returns its value or throws an error if the promise failed.
 - parameter promise: The promise to resolve.
 - throws: The error produced when the promise is rejected.
 - returns: The value of the promise when it is resolved.
 */
@discardableResult
public func await<T>(_ promise: Promise<T>) throws -> T {
  return try Queue.await.ak.await(promise)
}

/**
 Awaits that the given guarantee resolved and returns its value or throws an error if the current and target queues are the same.
 - parameter guarantee: The guarantee to resolve.
 - throws: when the queues are the same.
 - returns: The value of the guarantee when it is resolved.
 */
@discardableResult
public func await<T>(_ guarantee: Guarantee<T>) throws -> T {
  return try Queue.await.ak.await(guarantee)
}
