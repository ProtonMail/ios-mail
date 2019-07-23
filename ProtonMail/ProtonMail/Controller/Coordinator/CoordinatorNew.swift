//
//  CoordinatorNew.swift
//  ProtonMail - Created on 10/29/18.
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


protocol CoordinatorDelegate: class {
    func willStop(in coordinator: CoordinatorNew)
    func didStop(in coordinator: CoordinatorNew)
}

/// Used typically on view controllers to refer to it's coordinator
protocol CoordinatedNew : CoordinatedNewBase where coordinatorType: CoordinatorNew {
    associatedtype coordinatorType
    func set(coordinator: coordinatorType)
}

protocol CoordinatedNewBase : AnyObject {
    func getCoordinator() -> CoordinatorNew?
}

protocol CoordinatorNew : AnyObject {
    /// Triggers navigation to the corresponding controller
    /// set viewmodel and coordinator when call start
    func start()
    
    /// Stops corresponding controller and returns back to previous one
    func stop()
    
    /// Called when segue navigation form corresponding controller to different controller is about to start and should handle this navigation
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool
}

/// Navigate and stop methods are optional
extension CoordinatorNew {
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        return false
    }
    
    func stop() {
        
    }
}


/// The default coordinator is for the segue perform handled by system. need to return true in navigat function to trigger. if return false, need to push in the start().
protocol DefaultCoordinator: CoordinatorNew {
    associatedtype VC: UIViewController
    var viewController: VC? { get set }
    
    var animated: Bool { get }
    var delegate: CoordinatorDelegate? { get }
    
    var services: ServiceFactory {get}
    
    func follow(_ deepLink: DeepLink)
    func processDeepLink()
}


protocol PushCoordinator: DefaultCoordinator {
    var configuration: ((VC) -> ())? { get }
    var navigationController: UINavigationController? { get }
}

extension PushCoordinator where VC: UIViewController, VC: CoordinatedNew {
    func start() {
        guard let viewController = viewController else {
            return
        }
        configuration?(viewController)
        viewController.set(coordinator: self as! Self.VC.coordinatorType)
        navigationController?.pushViewController(viewController, animated: animated)
    }
    
    func stop() {
        delegate?.willStop(in: self)
        navigationController?.popViewController(animated: animated)
        delegate?.didStop(in: self)
    }
}

protocol ModalCoordinator: DefaultCoordinator {
    var configuration: ((VC) -> ())? { get }
    var navigationController: UINavigationController? { get }
    var destinationNavigationController: UINavigationController? { get }
}

extension ModalCoordinator where VC: UIViewController, VC: CoordinatedNew {
    func start() {
        guard let viewController = viewController else {
            return
        }
        
        configuration?(viewController)
        viewController.set(coordinator: self as! Self.VC.coordinatorType)
        
        if let destinationNavigationController = destinationNavigationController {
            // wrapper navigation controller given, present it
            navigationController?.present(destinationNavigationController, animated: animated, completion: nil)
        } else {
            // no wrapper navigation controller given, present actual controller
            navigationController?.present(viewController, animated: animated, completion: nil)
        }
    }
    
    func stop() {
        delegate?.willStop(in: self)
        viewController?.dismiss(animated: true, completion: {
            self.delegate?.didStop(in: self)
        })
    }
}


protocol PushModalCoordinator: DefaultCoordinator {
    var configuration: ((VC) -> ())? { get }
    var navigationController: UINavigationController? { get }
    var destinationNavigationController: UINavigationController? { get }
}

extension DefaultCoordinator {
    // default implementation if not overriden
    var animated: Bool {
        get {
            return true
        }
    }
    
    // default implementation of nil delegate, should be overriden when needed
    weak var delegate: CoordinatorDelegate? {
        get {
            return nil
        }
    }
    
    /// optional go with deeplink
    ///
    /// - Parameter deepLink: deepLink
    func follow(_ deepLink: DeepLink) {
        
    }
    
    /// if add deeplinks could handle here
    func processDeepLink() {
        
    }
}
