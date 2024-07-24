//
//  TOTPViewModel.swift
//  ProtonCore-LoginUI - Created on 8/5/24.
//
//  Copyright (c) 2024 Proton AG
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
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.

#if os(iOS)

import Foundation
import ProtonCoreUIFoundations
import ProtonCoreLogin
import ProtonCoreLog
import SwiftUI

extension TOTPView {
    @MainActor
    public class ViewModel: ObservableObject {
        @Published var tfaFieldContent: PCTextFieldContent!
        @Published var bannerState: BannerState = .none
        public weak var delegate: TwoFAProviderDelegate?
        @Published var isLoading = false

        public init() {

            tfaFieldContent = .init(
                title: LUITranslation.login_2fa_2fa_button_title.l10n,
                footnote: LUITranslation.login_2fa_field_info.l10n,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
        }

        func startValidation() {
            isLoading = true
            let code = tfaFieldContent.text

            Task {
                do {
                    try await delegate?.providerDidObtain(factor: code)
                    // don't update isLoading here, it stops way ahead of the view being dismissed
                } catch {
                    await MainActor.run {
                        isLoading = false
                        bannerState = .error(content: .init(message: error.localizedDescription))
                    }
                }
            }

        }
    }
}

#endif
