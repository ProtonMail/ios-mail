//
//  Created on 9/7/23.
//
//  Copyright (c) 2023 Proton AG
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
import SwiftUI

struct InactiveRecoveryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Currently there is no account recovery in process. Please go to a session on the web application to recover your password.",
                 bundle: AccountRecoveryModule.resourceBundle,
                 comment: "In the Account Recovery screen, text shown when there's no recovery process ongoing.")

        }
        .padding(16)
        .navigationTitle(ARTranslation.inactiveViewTitle.l10n)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InactiveRecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        InactiveRecoveryView()
    }
}
#endif
