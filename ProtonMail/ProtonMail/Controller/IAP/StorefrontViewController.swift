//
//  StorefrontViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_PaymentsUI
import ProtonCore_UIFoundations
import UIKit

class StorefrontViewController: UIViewController {

    private let coordinator: StorefrontCoordinator
    private let paymentsUI: PaymentsUIProtocol
    private let eventsService: EventsFetching

    init(coordinator: StorefrontCoordinator, paymentsUI: PaymentsUIProtocol, eventsService: EventsFetching) {
        self.coordinator = coordinator
        self.paymentsUI = paymentsUI
        self.eventsService = eventsService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpSelf()
        presentSubscriptions()
    }

    private func presentSubscriptions() {
        paymentsUI.showCurrentPlan(presentationType: .none,
                                   backendFetch: true) { [weak self] result in
            switch result {
            case let .open(viewController, opened) where !opened:
                self?.present(paymentsViewController: viewController)
            case .purchasedPlan:
                self?.eventsService.call()
            default:
                break
            }
        }
    }

    private func present(paymentsViewController: PaymentsUIViewController) {
        embed(paymentsViewController, inside: view)
    }

    private func setUpSelf() {
        title = LocalString._general_subscription

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Asset.topMenu.image,
            style: .plain,
            target: self,
            action: #selector(topMenuTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = ColorProvider.IconNorm
    }

    @objc
    private func topMenuTapped() {
        coordinator.handle(navigationAction: .menuTapped)
    }

}
