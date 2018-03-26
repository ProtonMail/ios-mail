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

extension Extension where Base: DispatchQueue {
  /**
   Yields the execution to the given closure and returns a new promise.

   - Parameter body: The closure that is executed on the given queue.
   - Returns: A new promise that is resolved when the provided closure returned.
   */
  public final func async<T>(_ body: @escaping () throws -> T) -> Promise<T> {
    return base.async(.promise, execute: body)
  }

  /**
   Yields the execution to the given closure which returns nothing.

   - Parameter body: The closure that is executed on the given queue.
   */
  public final func async(_ body: @escaping () throws -> Void) {
    let promise: Promise<Void> = async(body)

    promise.catch { _ in }
  }
}
