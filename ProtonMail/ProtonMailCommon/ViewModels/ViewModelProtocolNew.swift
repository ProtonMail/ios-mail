//
//  ViewModelProtocal.swift
//  ProtonMail - Created on 3/12/18.
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

//Notes for refactor later:
// view model need based on ViewModelBase
// view model factory control the view model impls
// view model impl control viewmodel navigate
// View model service tracking the ui flows

protocol ViewModelProtocolBase : AnyObject {
    func setModel(vm: Any)
    func inactiveViewModel() -> Void
}

protocol ViewModelProtocolNew : ViewModelProtocolBase {
    /// typedefine - view model -- if the class name defined in set function. the sub class could ignore viewModelType
    associatedtype viewModelType
    
    func set(viewModel: viewModelType) -> Void
}


extension ViewModelProtocolNew {
    func setModel(vm: Any) {
        guard let viewModel = vm as? viewModelType else {
            fatalError("This view model type doesn't match") //this shouldn't happend
        }
        self.set(viewModel: viewModel)
    }
    
    /// optional
    func inactiveViewModel() {
        
    }
}



//public protocol ViewModelOwner: class {
//    associatedtype ViewModelType
//
//    var viewModel: ViewModelType { get set }
//
//    func viewModelWasSet(viewModel: ViewModelType)
//}
//
//private var viewModelKey: UInt8 = 0
//
///**
// Extension for UIViewController that associates viewModel with it, as assosciated type, not concrete class, using Objective C runtime.
// */
//
//extension ViewModelOwner where Self: UIViewController {
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
//}
//
//
//
//public func associatedObject<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, constructor: () -> T) -> T {
//    if let associated = objc_getAssociatedObject(object, key) as? T {
//        return associated
//
//    }
//
//    let defaultValue = constructor()
//    objc_setAssociatedObject(object, key, defaultValue, .OBJC_ASSOCIATION_RETAIN)
//    return defaultValue
//}
//
//public func associateObject<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, value: T) {
//    objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN)
//}
//
//public func assertAssociatedObjectNil<T: Any>(object: AnyObject, key: UnsafePointer<UInt8>, type: T.Type, message error: String) {
//    if let _ = objc_getAssociatedObject(object, key) as? T {
//        fatalError(error)
//    }
//}

