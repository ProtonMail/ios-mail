//
//  AccountRecoveryView.swift
//  Created on 9/7/23.
//
//  Copyright (c) 2023 Proton AG
//
//  This file is part of ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.
#if os(iOS)
import SwiftUI

/// A View for showing the current status of an ongoing **Account Recovery** process, if any
public struct AccountRecoveryView: View {

    @StateObject var viewModel: ViewModel

    public var body: some View {
        switch (viewModel.isLoaded, viewModel.state) {
        case (false, _):
             SkeletonView()
        case (_, .grace):
             ActiveAccountRecoveryView(viewModel: viewModel)
        case (_, .insecure):
             InsecureAccountRecoveryView(viewModel: viewModel)
        case (_, .cancelled):
            CancelledAccountRecoveryView(viewModel: viewModel)
        case (_, .expired):
             ExpiredAccountRecoveryView()
        default:
            // This combo is not expected in the current MVP flow,
            // but we're adding it for exhaustiveness and for future-proofing.
             InactiveRecoveryView()
        }

    }

    /// Constructor taking a view model and where to connect it to
    /// - Parameter viewModel: The ViewModel that holds the data for this view
    public init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

}

struct AccountRecoveryView_Previews: PreviewProvider {

    static var viewModel = {
        let vm = AccountRecoveryView.ViewModel()
        vm.email = "norbert@example.com"
        vm.remainingTime = 3600 * 72
        vm.state = .grace
        vm.isLoaded = true
        return vm
    }()

    static var previews: some View {
        AccountRecoveryView(viewModel: Self.viewModel)
    }
}
#endif
