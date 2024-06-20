//
//  Created on 13/5/24.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import SwiftUI
import ProtonCoreServices
import ProtonCoreDataModel

public final class SecurityKeysViewController: UIHostingController<SecurityKeysView> {

    let viewModel: SecurityKeysView.ViewModel

     required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(apiService: APIService, clientApp: ClientApp, showingDismissButton: Bool) {
        self.viewModel = SecurityKeysView.ViewModel(apiService: apiService, productName: clientApp.displayName, showingDismissButton: showingDismissButton)
        let view = SecurityKeysView(viewModel: viewModel)
        super.init(rootView: view)
        self.viewModel.navigationDelegate = self
    }

    override public func viewDidLoad() {
        UITableView.appearance(whenContainedInInstancesOf: [UIHostingController<SecurityKeysView>.self]).backgroundColor = .clear
    }
}

extension SecurityKeysViewController: NavigationDelegate {
    public func userDidGoBack() {
        navigationController?.popViewController(animated: true)
    }
}

#endif
