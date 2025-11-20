// Copyright (c) 2025 Proton Technologies AG
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

import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct EmptyFolderBannerView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @EnvironmentObject var upsellCoordinator: UpsellCoordinator
    private let model: EmptyFolderBanner
    private let mailUserSession: MailUserSession
    private let wrapper: RustEmptyFolderBannerWrapper

    init(model: EmptyFolderBanner, mailUserSession: MailUserSession, wrapper: RustEmptyFolderBannerWrapper) {
        self.model = model
        self.mailUserSession = mailUserSession
        self.wrapper = wrapper
    }

    var body: some View {
        StoreView(
            store: EmptyFolderBannerStateStore(
                model: model,
                toastStateStore: toastStateStore,
                mailUserSession: mailUserSession,
                wrapper: wrapper,
                upsellScreenPresenter: upsellCoordinator
            )
        ) { state, store in
            VStack(alignment: .leading, spacing: DS.Spacing.medium) {
                HStack(alignment: .top, spacing: DS.Spacing.moderatelyLarge) {
                    BannerIconTextView(
                        icon: state.icon,
                        title: state.title,
                        subtitle: nil,
                        style: .regular,
                        lineLimit: .none
                    )
                }
                .horizontalPadding()
                ForEachLast(collection: store.state.buttons) { type, isLast in
                    VStack(spacing: DS.Spacing.medium) {
                        BannerButton(
                            model: buttonModel(from: type, store: store),
                            style: type.style,
                            maxWidth: .infinity
                        )
                        .buttonStyle(.plain)
                        .horizontalPadding()
                        if !isLast {
                            DS.Color.Border.light.frame(height: 1).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding([.top, .bottom], DS.Spacing.medium)
            .background {
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .fill(DS.Color.Background.norm)
                    .stroke(DS.Color.Border.norm, lineWidth: 1)
                    .shadow(DS.Shadows.softFull, isVisible: true)
            }
            .frame(maxWidth: .infinity)
            .alert(model: store.binding(\.alert))
            .sheet(item: store.binding(\.presentedUpsell)) { upsellScreenModel in
                UpsellScreen(model: upsellScreenModel)
            }
        }
    }

    // MARK: - Private

    private func buttonModel(
        from type: EmptyFolderBanner.ActionButton,
        store: EmptyFolderBannerStateStore
    ) -> Banner.Button {
        let model: Banner.Button

        switch type {
        case .upgradePlan:
            model = .init(title: L10n.EmptyFolderBanner.upgradeAction) {
                store.handle(action: .upgradeToAutoDelete)
            }
        case .emptyLocation:
            let folder = store.model.folder.type.humanReadable.lowercased()

            model = .init(title: L10n.EmptyFolderBanner.emptyNowAction(folderName: folder)) {
                store.handle(action: .emptyFolder)
            }
        }

        return model
    }
}

private extension View {

    func horizontalPadding() -> some View {
        padding([.leading, .trailing], DS.Spacing.large)
    }

}

private extension EmptyFolderBanner.ActionButton {

    var style: Banner.ButtonStyle {
        switch self {
        case .upgradePlan:
            .gradient
        case .emptyLocation:
            .regular
        }
    }

}

#Preview {
    ScrollView {
        VStack(alignment: .center, spacing: 10) {
            EmptyFolderBannerView.preview(model: .init(folder: .preview(type: .spam), userState: .autoDeleteUpsell))
            EmptyFolderBannerView.preview(model: .init(folder: .preview(type: .spam), userState: .autoDeleteDisabled))
            EmptyFolderBannerView.preview(model: .init(folder: .preview(type: .spam), userState: .autoDeleteEnabled))

            EmptyFolderBannerView.preview(model: .init(folder: .preview(type: .trash), userState: .autoDeleteUpsell))
            EmptyFolderBannerView.preview(model: .init(folder: .preview(type: .trash), userState: .autoDeleteDisabled))
            EmptyFolderBannerView.preview(model: .init(folder: .preview(type: .trash), userState: .autoDeleteEnabled))
        }
        .padding([.leading, .trailing], DS.Spacing.large)
        .environmentObject(ToastStateStore(initialState: .initial))
    }
}

private extension EmptyFolderBannerView {

    static func preview(model: EmptyFolderBanner) -> Self {
        .init(model: model, mailUserSession: .dummy, wrapper: .previewInstance())
    }

}

private extension EmptyFolderBanner.FolderDetails {

    static func preview(type: SpamOrTrash) -> Self {
        .init(labelID: .random(), type: type)
    }

}
