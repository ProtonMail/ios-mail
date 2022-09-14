//
//  TroubleShootingHelper.swift
//  ProtonCore-TroubleShooting - Created on 08/20/2020
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.
//

import ProtonCore_Doh

// use this call back to update your local cache
public typealias OnStatusChanged = (_ newStatus: DoHStatus) -> Void

class DohStatusHelper: DohStatusProtocol {
    var doh: DoH
    init(doh: DoH) {
        self.doh = doh
    }
    
    var onChanged: OnStatusChanged = { newStatus in }
    
    var status: DoHStatus {
        get {
            return doh.status
        }
        set {
            self.doh.status = newValue
            self.onChanged(newValue)
        }
    }
}

public class TroubleShootingHelper {
    
    let viewModel: TroubleShootingViewModel
    public init(doh: DoH, dohStatusChanged: OnStatusChanged? = nil) {
        let statusHelper = DohStatusHelper(doh: doh)
        if let statusChanged = dohStatusChanged {
            statusHelper.onChanged = statusChanged
        }
        self.viewModel = TroubleShootingViewModel(doh: statusHelper)
    }
    
    public func showTroubleShooting(over viewController: UIViewController, dismiss: OnDismissComplete? = nil) {
        let troubleShootView = TroubleShootingViewController(viewModel: viewModel)
        if let dismiss = dismiss {
            troubleShootView.onDismiss = dismiss
        }
        let nav = UINavigationController(rootViewController: troubleShootView)
        viewController.present(nav, animated: true)
    }
}

extension UIViewController {
    
    public func present(doh: DoH,
                        dohStatusChanged: OnStatusChanged? = nil,
                        onDismiss: OnDismissComplete? = nil) {
        let statusHelper = DohStatusHelper(doh: doh)
        if let statusChanged = dohStatusChanged {
            statusHelper.onChanged = statusChanged
        }
        let viewModel = TroubleShootingViewModel(doh: statusHelper)
        let troubleShootView = TroubleShootingViewController(viewModel: viewModel)
        if let dismiss = onDismiss {
            troubleShootView.onDismiss = dismiss
        }
        let nav = UINavigationController(rootViewController: troubleShootView)
        self.present(nav, animated: true)
    }
}
