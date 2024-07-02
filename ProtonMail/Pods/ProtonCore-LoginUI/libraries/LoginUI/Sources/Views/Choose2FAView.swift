//
//  Choose2FAView.swift
//  ProtonCore-Login - Created on 08/05/2024.
//
//  Copyright (c) 2024 Proton AG
//
//  This file is part of Proton AG and ProtonCore.
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

import SwiftUI
import ProtonCoreLogin
import ProtonCoreUIFoundations

enum TwoFAType {
    case totp
    case fido2
}

@available(iOS 15.0, *)
public struct Choose2FAView: View {

    @State private var selectedType: TwoFAType = .fido2

    @ObservedObject var totpViewModel: TOTPView.ViewModel
    @ObservedObject var fido2ViewModel: Fido2View.ViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Please choose how you want to confirm your identity.",
                 bundle: LUITranslation.bundle,
                 comment: "2FA choice screen header")
            Picker("Type", selection: $selectedType) {
                Text("Security key",
                     bundle: LUITranslation.bundle,
                     comment: "A hardware based FIDO2 key")
                .tag(TwoFAType.fido2)
                Text("One-time code",
                     bundle: LUITranslation.bundle,
                     comment: "Single use TOTP code")
                .tag(TwoFAType.totp)
            }
            .pickerStyle(.segmented)
            .disabled(totpViewModel.isLoading || fido2ViewModel.isLoading)

            selectedView

        }
        .font(.title3)
        .padding(20)
        .navigationTitle(Text("Two-Factor Authentication",
                              bundle: LUITranslation.bundle,
                              comment: "2FA screen title"))
        .navigationBarTitleDisplayMode(.inline)
        .foregroundColor(ColorProvider.TextNorm)
        .background(ColorProvider.BackgroundNorm)
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .top)
        .bannerDisplayable(bannerState: $totpViewModel.bannerState,
                           configuration: .default())
        .bannerDisplayable(bannerState: $fido2ViewModel.bannerState,
                           configuration: .default())
    }

    @ViewBuilder var selectedView: some View {
        switch selectedType {
        case .totp:
            TOTPView(viewModel: totpViewModel)
        case .fido2:
            Fido2View(viewModel: fido2ViewModel,
                      isNested: true)

        }
    }

    public init(totpViewModel: TOTPView.ViewModel, fido2ViewModel: Fido2View.ViewModel) {
        self.totpViewModel = totpViewModel
        self.fido2ViewModel = fido2ViewModel
    }
}

#if DEBUG

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            Choose2FAView(totpViewModel: TOTPView.ViewModel(),
                          fido2ViewModel: Fido2View.ViewModel.initial)
        }
    } else if #available(iOS 15.0, *) {
        Choose2FAView(totpViewModel: TOTPView.ViewModel(),
                      fido2ViewModel: Fido2View.ViewModel.initial)
    } else {
        // Fallback on earlier versions
        Text("🦖 This view is not available for iOS versions < 15.0")
    }
}

#endif
#endif
