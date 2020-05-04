//
//  CoordinatorNew.swift
//  ProtonMail - Created on 10/29/18.
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


protocol CoordinatorDelegate: class {
    func willStop(in coordinator: CoordinatorNew)
    func didStop(in coordinator: CoordinatorNew)
}

/// Used typically on view controllers to refer to it's coordinator
protocol CoordinatedNew : CoordinatedNewBase where coordinatorType: CoordinatorNew {
    associatedtype coordinatorType
    func set(coordinator: coordinatorType)
}

protocol CoordinatedAlerts {
    func controller(notFount dest: String)
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
