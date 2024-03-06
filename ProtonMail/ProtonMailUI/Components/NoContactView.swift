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

    public struct Texts {
        private let title: String
        private let description: String
        private let importingTitle: String
        private let importingDesc: String
        let buttonTitle: String
        let noPermissionAlertTitle: String
        let noPermissionAlertMessage: String
        let noPermissionButtonTitle: String

        public init(
            title: String,
            description: String,
            importingTitle: String,
            importingDesc: String,
            buttonTitle: String,
            noPermissionAlertTitle: String,
            noPermissionAlertMessage: String,
            noPermissionButtonTitle: String
        ) {
            self.title = title
            self.description = description
            self.importingTitle = importingTitle
            self.importingDesc = importingDesc
            self.buttonTitle = buttonTitle
            self.noPermissionAlertTitle = noPermissionAlertTitle
            self.noPermissionAlertMessage = noPermissionAlertMessage
            self.noPermissionButtonTitle = noPermissionButtonTitle
        }

        func displayedTitle(isImporting: Bool) -> String {
            isImporting ? importingTitle : title
        }

        func displayedDesc(isImporting: Bool) -> String {
            isImporting ? importingDesc : description
        }
    }
}

public struct NoContactView: View {
    public let config = HostingProvider()
    private let texts: Texts
    private let importingClosure: ((UIViewController?) -> Void)?
    private let store = CNContactStore()
    @State private var verticalPadding = Constants.paddingForPortrait
    @State private var isImporting: Bool
    @State private var showingAlert: Bool = .init(false)

    public init(
        texts: Texts,
        isImporting: Bool,
        importingClosure: ((UIViewController?) -> Void)?
    ) {
        self.texts = texts
        _isImporting = .init(initialValue: isImporting)
        self.importingClosure = importingClosure
    }

    public var body: some View {
        VStack(spacing: verticalPadding) {
            Image(uiImage: ImageAsset.autoImportContactsNoContact)
            Text(texts.displayedTitle(isImporting: isImporting))
                .font(Font(UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)))
            Text(texts.displayedDesc(isImporting: isImporting))
                .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                .multilineTextAlignment(.center)

            if isImporting {
                Rectangle()
                    .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
                    .foregroundColor(.clear)
            } else {
                Button(action: {
                    self.importButtonIsClicked()
                }, label: {
                    Text(texts.buttonTitle)
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
                title: Text(texts.noPermissionAlertTitle),
                message: Text(texts.noPermissionAlertMessage),
                dismissButton: .cancel(Text(texts.noPermissionButtonTitle))
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
        isImporting.toggle()
        importingClosure?(config.hostingController)
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
    NoContactView(
        texts: .init(
            title: "No contacts yet",
            description: "Import contacts from your device to send emails and invites with ease. ",
            importingTitle: "Importing your contacts",
            importingDesc: "Your contacts will appear here shortly.",
            buttonTitle: "Auto-import contacts",
            noPermissionAlertTitle: "Auto-import device contacts",
            noPermissionAlertMessage: "Access to contacts was disabled. To enable auto-import, go to settings and enable contact permission.",
            noPermissionButtonTitle: "Ok"
        ),
        isImporting: false
    ) { _ in
        print("click button")
    }
}
