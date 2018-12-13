//
//  ViewModelProtocal.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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

