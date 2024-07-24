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

import SwiftUI
import ProtonCoreUIFoundations

public struct SecurityKeysView: View {

    enum Constants {
        static let iconImageSize: CGFloat = 20
        static let iconButtonSize: CGFloat = 40
    }

    @ObservedObject var viewModel: ViewModel

    public var body: some View {
        VStack {
            switch viewModel.viewState {
            case .initial:
                Spacer()
            case .loading:
                Text("Fetching your security keys details",
                     bundle: LoginUIModule.resourceBundle,
                     comment: "Placeholder text while loading the list of security keys")
                .padding(20)
                ProgressView()
                    .progressViewStyle(.circular)
            case .loaded(let keys):
                if keys.isEmpty {
                    Text("You don't yet have any security keys enrolled in your account. Please use the Proton \(viewModel.productName) web application to add security keys.",
                         bundle: LoginUIModule.resourceBundle,
                         comment: "Empty test for the list of security keys, with a %@ placeholder for the product name")
                    .padding(20)
                } else {
                    List {
                        Section {
                            ForEach(keys) {
                                Text($0.name)
                                    .foregroundColor(ColorProvider.TextNorm)
                            }
                        } header: {
                                Text("These are the security keys registered to your account",
                                     bundle: LoginUIModule.resourceBundle,
                                     comment: "Header before showing list of security keys")
                                .apply {
                                    if #available(iOS 16.0, *) {
                                        $0.lineLimit(2, reservesSpace: true)
                                    }
                                }
                                .textCase(nil)
                        } footer: {
                            Text("To manage, add, or remove security keys, please use the Proton \(viewModel.productName) web application.",
                                 bundle: LoginUIModule.resourceBundle,
                                 comment: "Footer after showing list of security keys, with a %@ placeholder for the product name")
                            .foregroundColor(ColorProvider.TextWeak)
                        }
                        .listRowBackground(ColorProvider.BackgroundSecondary)
                    }
                    .apply {
                        if #available(iOS 16.0, *) {
                            $0.scrollContentBackground(.hidden)
                        } else {
                            $0
                        }
                    }
                }
            case .error:
                Text("An error occurred fetching your security keys. You can also check them on the Proton \(viewModel.productName) website.",
                     bundle: LoginUIModule.resourceBundle,
                     comment: "Message shown after an error while loading the list of security keys, with a %@ placeholder for the product name"
                )
                .padding(20)
            }
        }
        .if(viewModel.showingDismissButton) { view in
            view.navigationBarItems(leading: dismissButton())
        }
        .foregroundColor(ColorProvider.TextWeak)
        .navigationTitle(Text("Security Keys",
                              bundle: LoginUIModule.resourceBundle,
                              comment: "Title for Security Keys list screen"))
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .top)
        .onAppear {
            guard !Self.isRunningTests else { return }
            viewModel.loadKeys()
        }
    }

    @ViewBuilder
    private func dismissButton() -> some View {
        switch Brand.currentBrand {
        case .proton, .vpn:
            Button(action: { viewModel.dismiss() }, label: {
                Text("Close")
                    .foregroundColor(ColorProvider.InteractionNorm)
            })
        case .pass, .wallet:
            ZStack {
                ColorProvider.PurpleBase.opacity(0.2)
                    .clipShape(Circle())

                Image(uiImage: IconProvider.cross)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(ColorProvider.PurpleBase)
                    .frame(width: Constants.iconImageSize, height: Constants.iconImageSize)
            }
            .frame(width: Constants.iconButtonSize, height: Constants.iconButtonSize)
            .onTapGesture { viewModel.dismiss() }
        }
    }

    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

}

#if DEBUG

@testable import ProtonCoreServices

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            SecurityKeysView(viewModel: SecurityKeysView.ViewModel())
        }
    } else {
        SecurityKeysView(viewModel: SecurityKeysView.ViewModel())
    }
}

#endif
#endif
