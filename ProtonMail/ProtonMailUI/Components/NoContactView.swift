// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Contacts
import ProtonCoreUIFoundations
import SwiftUI

extension NoContactView {
    enum Constants {
        static let paddingForPortrait: CGFloat = 22
        static let paddingForLandscape: CGFloat = 6
        static let horizontalPadding: CGFloat = 32
    }
}

public class NoContactViewModel: ObservableObject {
    static let shared: NoContactViewModel = .init()
    @Published public var isAutoImportContactsEnabled: Bool = false
    public var onDidTapAutoImport: (() -> Void)?
}

public struct NoContactView: View {
    @ObservedObject public var model: NoContactViewModel = .shared

    @State private var verticalPadding = Constants.paddingForPortrait
    @State private var showingAlert: Bool = .init(false)

    private let store = CNContactStore()

    public init() {}

    private func displayedTitle(isImporting: Bool) -> String {
        isImporting ? L10n.AutoImportContacts.importingTitle : L10n.AutoImportContacts.noContactTitle
    }

    private func displayedDesc(isImporting: Bool) -> String {
        isImporting ? L10n.AutoImportContacts.importingDesc : L10n.AutoImportContacts.noContactDesc
    }

    public var body: some View {
        VStack(spacing: verticalPadding) {
            Image(.autoImportContactsNoContact)
            Text(displayedTitle(isImporting: model.isAutoImportContactsEnabled))
                .font(Font(UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)))
            Text(displayedDesc(isImporting: model.isAutoImportContactsEnabled))
                .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                .multilineTextAlignment(.center)

            if model.isAutoImportContactsEnabled {
                Rectangle()
                    .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
                    .foregroundColor(.clear)
            } else {
                Button(action: {
                    self.importButtonIsClicked()
                }, label: {
                    Text(L10n.AutoImportContacts.autoImportContactButtonTitle)
                        .frame(maxWidth: .infinity, minHeight: 48)

                })
                .buttonStyle(AutoImportButtonStyle())
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .onAppear(perform: {
            self.updateVerticalPadding()
        })
        .onReceive(
            NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification),
            perform: { _ in
                self.updateVerticalPadding()
            }
        )
        .alert(isPresented: $showingAlert, content: {
            Alert(
                title: Text(L10n.SettingsContacts.autoImportContacts),
                message: Text(L10n.SettingsContacts.authoriseContactsInSettingsApp),
                dismissButton: .cancel(Text(LocalString._general_ok_action))
            )
        })
    }

    @MainActor
    private func updateVerticalPadding() {
        let orientation = UIDevice.current.orientation
        verticalPadding = orientation.isPortrait ? Constants.paddingForPortrait : Constants.paddingForLandscape
    }

    private func importButtonIsClicked() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            requestContactPermission()
        case .denied:
            showAccessDenyAlert()
        case .authorized, .restricted:
            startsToImportContact()
        default:
            return
        }
    }

    private func requestContactPermission() {
        store.requestAccess(for: .contacts) { isSuccess, _ in
            if isSuccess {
                self.startsToImportContact()
            }
        }
    }

    private func showAccessDenyAlert() {
        showingAlert.toggle()
    }

    private func startsToImportContact() {
        model.isAutoImportContactsEnabled.toggle()
        model.onDidTapAutoImport?()
    }
}

private struct AutoImportButtonStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
            .foregroundColor(ColorProvider.TextAccent)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(configuration.isPressed ? ColorProvider.BackgroundSecondary : Color.clear)
            .clipShape(RoundedRectangle(cornerSize: .init(width: 8, height: 8)))
    }
}

#Preview {
    NoContactView()
}
