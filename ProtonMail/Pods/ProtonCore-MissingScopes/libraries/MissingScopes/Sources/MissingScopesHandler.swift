//
//  MissingScopesHandler.swift
//  ProtonCore-MissingScopes - Created on 26/04/23.
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

#if os(iOS)

import UIKit
import ProtonCoreAPIClient
import ProtonCoreAuthentication
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUtilities
import ProtonCoreUIFoundations

public class MissingScopesHandler: MissingScopesDelegate {
    private let apiService: APIService
    private let inAppTheme: () -> InAppTheme
    private let authService: AuthService
    private let queue: CompletionBlockExecutor
    private var missingScopesCoordinator: MissingScopesCoordinatorDelegate?

    public init(apiService: APIService,
                inAppTheme: @escaping () -> InAppTheme = { .default },
                queue: CompletionBlockExecutor = .asyncMainExecutor,
                missingScopesCoordinator: MissingScopesCoordinatorDelegate? = nil) {
        self.apiService = apiService
        self.inAppTheme = inAppTheme
        self.queue = queue
        self.missingScopesCoordinator = missingScopesCoordinator
        self.authService = .init(api: apiService)
    }

    public func onMissingScopesHandling(missingScopeMode: MissingScopeMode, username: String, responseHandlerData: PMResponseHandlerData, completion: @escaping (MissingScopesFinishReason) -> Void) {
        queue.execute {
            if self.missingScopesCoordinator == nil {
                let missingScopesCoordinator = MissingScopesCoordinator(
                    apiService: self.apiService,
                    username: username,
                    missingScopeMode: missingScopeMode,
                    inAppTheme: self.inAppTheme,
                    responseHandlerData: responseHandlerData,
                    completion: { [weak self] finishReason in
                        self?.missingScopesCoordinator = nil
                        completion(finishReason)
                    }
                )
                self.missingScopesCoordinator = missingScopesCoordinator
            }
            self.missingScopesCoordinator?.showAskPassword()
        }
    }

    public func showAlert(title: String, message: String?) {
        queue.execute {
            let topViewController = UIViewController.topVC
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            topViewController?.present(alertController, animated: true, completion: nil)
        }
    }
}

#endif
