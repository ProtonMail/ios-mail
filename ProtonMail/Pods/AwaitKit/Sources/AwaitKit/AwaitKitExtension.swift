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
import Dispatch

/// The generic object to add an `ak` category. Here the base will be the DispatchQueue.
public final class Extension<Base> {
  /// The base class.
  public let base: Base

  /// Init with the base class.
  public init(_ base: Base) {
    self.base = base
  }
}

/**
 A type that has AwaitKit extensions.
 */
public protocol AwaitKitCompatible {
  associatedtype CompatibleType

  /// The `ak` category.
  var ak: CompatibleType { get }
}

public extension AwaitKitCompatible {
  /// By default the `ak` category returns an Extension object which contains itself.
  var ak: Extension<Self> {
    get { return Extension(self) }
  }
}

/// Extends the DispatchQueue to support the AwaitKit.
extension DispatchQueue: AwaitKitCompatible { }
