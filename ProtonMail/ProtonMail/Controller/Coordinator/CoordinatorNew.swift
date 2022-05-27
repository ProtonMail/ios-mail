//
//  CoordinatorNew.swift
//  Proton Mail - Created on 10/29/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

protocol CoordinatorDelegate: AnyObject {
    func willStop(in coordinator: CoordinatorNew)
    func didStop(in coordinator: CoordinatorNew)
}

/// Used typically on view controllers to refer to it's coordinator
protocol CoordinatedNew: CoordinatedNewBase where coordinatorType: CoordinatorNew {
    associatedtype coordinatorType
    func set(coordinator: coordinatorType)
}

protocol CoordinatedNewBase: AnyObject {
}

protocol CoordinatorNew: AnyObject {
    /// Triggers navigation to the corresponding controller
    /// set viewmodel and coordinator when call start
    func start()
}

/// The default coordinator is for the segue perform handled by system. need to return true in navigat function to trigger. if return false, need to push in the start().
protocol DefaultCoordinator: CoordinatorNew {
    associatedtype VC: UIViewController
    var viewController: VC? { get set }

    var delegate: CoordinatorDelegate? { get }
}

protocol PushCoordinator: DefaultCoordinator {
    var configuration: ((VC) -> Void)? { get }
    var navigationController: UINavigationController? { get }
}

extension PushCoordinator where VC: CoordinatedNew {
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
    var configuration: ((VC) -> Void)? { get }
    var navigationController: UINavigationController? { get }
    var destinationNavigationController: UINavigationController? { get }
}

extension ModalCoordinator where VC: CoordinatedNew {
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
}
