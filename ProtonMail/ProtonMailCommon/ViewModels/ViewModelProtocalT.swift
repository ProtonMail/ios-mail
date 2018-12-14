//
//  ViewModelProtocalT.swift
//  ProtonMail - Created on 5/23/18.
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


/// this file is not in use because it is an experimental structure.
/// reason: everytime access viewModel needs to go thorugh this wrapper which is not good.

private var viewModelKey: UInt8 = 0
public protocol ViewModelOwner: class {
    associatedtype ViewModelType
    var viewModel: ViewModelType { get set }
    func viewModelDidSet(viewModel: ViewModelType)
}

/**
 Extension for UIViewController that associates viewModel with it, as assosciated type, not concrete class, using Objective C runtime.
 */
extension ViewModelOwner where Self: UIViewController {
    public var viewModel: ViewModelType {
        get {
            return associatedObject(object: self, key: &viewModelKey, constructor: { () -> ViewModelType in
                fatalError("viewModel has not yet been set")
            })
        }
        set {
            assertAssociatedObjectNil(object: self, key: &viewModelKey, type: ViewModelType.self, message: "viewModel has already been set")
            associateObject(object: self, key: &viewModelKey, value: newValue)
            viewModelDidSet(viewModel: newValue)
        }
    }
}

public func associatedObject<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, constructor: () -> T) -> T {
    if let associated = objc_getAssociatedObject(object, key) as? T {
        return associated

    }
    let defaultValue = constructor()
    objc_setAssociatedObject(object, key, defaultValue, .OBJC_ASSOCIATION_RETAIN)
    return defaultValue
}

public func associateObject<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, value: T) {
    objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN)
}

public func assertAssociatedObjectNil<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, type: T.Type, message error: String) {
    if let _ = objc_getAssociatedObject(object, key) as? T {
        fatalError(error)
    }
}
