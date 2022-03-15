//
//  ViewModelProtocalT.swift
//  ProtonMail - Created on 5/23/18.
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

/// this file is not in use because it is an experimental structure.
/// reason: everytime access viewModel needs to go thorugh this wrapper which is not good.

private var viewModelKey: UInt8 = 0
public protocol ViewModelOwner: AnyObject {
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

// public protocol ViewModelOwner: class {
//    associatedtype ViewModelType
//
//    var viewModel: ViewModelType { get set }
//
//    func viewModelWasSet(viewModel: ViewModelType)
// }
//
// private var viewModelKey: UInt8 = 0
//
/// **
// Extension for UIViewController that associates viewModel with it, as assosciated type, not concrete class, using Objective C runtime.
// */
//
// extension ViewModelOwner where Self: UIViewController {
//    public var viewModel: ViewModelType {
//        get {
//            return associatedObject(object: self, key: &viewModelKey, constructor: { () -> ViewModelType in
//                fatalError("viewModel has not yet been set")
//            })
//        }
//
//        set {
//            assertAssociatedObjectNil(object: self, key: &viewModelKey, type: ViewModelType.self, message: "viewModel has already been set")
//            associateObject(object: self, key: &viewModelKey, value: newValue)
//            viewModelWasSet(viewModel: newValue)
//        }
//    }
// }
//
//
//
// public func associatedObject<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, constructor: () -> T) -> T {
//    if let associated = objc_getAssociatedObject(object, key) as? T {
//        return associated
//
//    }
//
//    let defaultValue = constructor()
//    objc_setAssociatedObject(object, key, defaultValue, .OBJC_ASSOCIATION_RETAIN)
//    return defaultValue
// }
//
// public func associateObject<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, value: T) {
//    objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN)
// }
//
// public func assertAssociatedObjectNil<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, type: T.Type, message error: String) {
//    if let _ = objc_getAssociatedObject(object, key) as? T {
//        fatalError(error)
//    }
// }
