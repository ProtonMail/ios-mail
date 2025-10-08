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

import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import proton_app_uniffi
import SwiftUI

struct SidebarScreen: View {
    private enum AxisLock {
        case none, horizontal, vertical
    }

    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @StateObject private var screenModel: SidebarModel
    @State private var headerHeight: CGFloat = .zero
    @State private var lockedAxis: AxisLock = .none
    @State private var dragStartWidth: CGFloat?

    private let widthOfDragableSpaceOnTheMailbox: CGFloat = 25
    private let openCloseSidebarMinimumDistance: CGFloat = 30
    /// This value is to make sure a twitch of a finger when releasing the sidebar won't cause the sidebar to move in the other direction against user's wishes.
    private let lastSwipeSignificanceThreshold: CGFloat = 25
    private let animationDuration = 0.2
    private let selectedItem: (SidebarItem) -> Void
    private let appVersionProvider: AppVersionProvider

    init(
        state: SidebarState,
        userSession: MailUserSession,
        upsellButtonVisibilityPublisher: UpsellButtonVisibilityPublisher,
        appVersionProvider: AppVersionProvider = .init(),
        sidebarFactory: @escaping (MailUserSession) -> SidebarProtocol = Sidebar.init,
        selectedItem: @escaping (SidebarItem) -> Void
    ) {
        let screenModel = SidebarModel(
            state: state,
            sidebar: sidebarFactory(userSession),
            upsellButtonVisibilityPublisher: upsellButtonVisibilityPublisher
        )

        _screenModel = .init(wrappedValue: screenModel)
        self.selectedItem = selectedItem
        self.appVersionProvider = appVersionProvider
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                opacityBackground
                    .gesture(closeSidebarTapGesture)
                    .frame(width: 2 * geometry.size.width)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: appUIStateStore.sidebarWidth + geometry.safeAreaInsets.leading + widthOfDragableSpaceOnTheMailbox)
                    .highPriorityGesture(sidebarDragGesture)
                    .gesture(appUIStateStore.sidebarState.isOpen ? closeSidebarTapGesture : nil)

                HStack(spacing: .zero) {
                    sideBarBackground
                        .frame(width: geometry.safeAreaInsets.leading)
                    ZStack(alignment: .topLeading) {
                        sideBarBackground
                            .shadow(DS.Shadows.liftedRight, isVisible: appUIStateStore.sidebarState.isOpen)
                        sideBarItemsList
                            .safeAreaPadding(.top, headerHeight)
                        header
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SidebarScreenIdentifiers.rootItem)
                }
                .frame(width: appUIStateStore.sidebarWidth)
                .simultaneousGesture(sidebarDragGesture)
            }
            .animation(.easeOut(duration: animationDuration), value: appUIStateStore.sidebarState.visibleWidth)
            .offset(x: appUIStateStore.sidebarState.visibleWidth - appUIStateStore.sidebarWidth - geometry.safeAreaInsets.leading)
        }
        .onAppear { screenModel.handle(action: .viewAppear) }
        .onOpenURL(perform: handleDeepLink)
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Image(DS.Images.mailProductLogo)
                .padding(.leading, DS.Spacing.extraLarge)
                .padding(.vertical, DS.Spacing.small)
                .onTapGesture(count: 5) { screenModel.handle(action: .logoTappedFiveTimes) }
            separator
        }.background(
            GeometryReader { geometry in
                TransparentBlur()
                    .edgesIgnoringSafeArea(.all)
                    .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                    .onPreferenceChange(HeightPreferenceKey.self) { value in
                        headerHeight = value
                    }
            }
        )
    }

    /// Minimum movement (pts) before locking axis.
    /// Avoids accidental lock from tiny diagonal wiggles.
    private let axisSlop: CGFloat = 6

    private var sidebarDragGesture: some Gesture {
        DragGesture(minimumDistance: .zero, coordinateSpace: .global)
            .onChanged { value in
                if dragStartWidth == nil {
                    dragStartWidth = appUIStateStore.sidebarState.visibleWidth
                }

                if lockedAxis == .none {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)

                    if max(dx, dy) > axisSlop {
                        lockedAxis = dx > dy ? .horizontal : .vertical
                    }
                }

                if lockedAxis == .horizontal {
                    guard let startWidth = dragStartWidth else {
                        return
                    }

                    let dragTranslation = value.translation.width
                    let newWidth = startWidth + dragTranslation

                    let clampedWidth = min(appUIStateStore.sidebarWidth, max(0, newWidth))
                    appUIStateStore.sidebarState.visibleWidth = clampedWidth
                }
            }
            .onEnded { value in
                guard lockedAxis == .horizontal else {
                    lockedAxis = .none
                    return
                }

                defer {
                    dragStartWidth = nil
                    lockedAxis = .none
                }

                let predictedEndWidth = value.predictedEndTranslation.width
                let predictedDx = predictedEndWidth - value.translation.width
                let hasPredictedSignificantSlide = abs(predictedDx) > lastSwipeSignificanceThreshold

                let shouldBeOpen: Bool

                if hasPredictedSignificantSlide {
                    shouldBeOpen = predictedEndWidth > 0
                } else {
                    let state = appUIStateStore
                    let isCloserToOpenThanClosed = state.sidebarState.visibleWidth > state.sidebarWidth / 2
                    shouldBeOpen = isCloserToOpenThanClosed
                }

                appUIStateStore.toggleSidebar(isOpen: shouldBeOpen)
            }
    }

    private var closeSidebarTapGesture: some Gesture {
        TapGesture()
            .onEnded { appUIStateStore.toggleSidebar(isOpen: false) }
    }

    private var opacityBackground: some View {
        DS.Color.Global.modal
            .animation(.linear(duration: animationDuration), value: appUIStateStore.sidebarState.visibleWidth)
            .opacity(0.5 * (appUIStateStore.sidebarState.visibleWidth / appUIStateStore.sidebarWidth))
            .ignoresSafeArea(.all)
    }

    private var sideBarBackground: some View {
        DS.Color.Sidebar.background
            .edgesIgnoringSafeArea(.all)
    }

    private var sideBarItemsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    VStack(spacing: .zero) {
                        if let upsellItem = screenModel.state.upsell {
                            upsellSidebarItem(item: upsellItem)
                        }
                        systemFoldersList()
                    }
                    .padding(.vertical, DS.Spacing.medium)

                    separator
                    customFoldersList()
                        .padding(.vertical, DS.Spacing.medium)
                    separator
                    labelsList()
                        .padding(.vertical, DS.Spacing.medium)
                    separator
                    otherItemsList()
                        .padding(.vertical, DS.Spacing.medium)
                    separator
                    appVersionNote
                }.onChange(of: appUIStateStore.sidebarState.isOpen) { _, isSidebarOpen in
                    if isSidebarOpen, let first = screenModel.state.items.first {
                        proxy.scrollTo(first.id, anchor: .zero)
                    }
                }.accessibilityElement(children: .contain)
            }
            .scrollDisabled(lockedAxis == .horizontal)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func upsellSidebarItem(item: SidebarItem) -> some View {
        let planName = UpsellConfiguration.mail.humanReadableUpsoldPlanName

        SidebarItemButton(
            item: item,
            action: { select(item: item) },
            content: {
                HStack(spacing: .zero) {
                    sidebarItemImage(icon: DS.Icon.icDiamond.image, isSelected: false, renderingMode: .original)
                    itemNameLabel(name: L10n.Sidebar.upgrade(to: planName).string, isSelected: false)
                    Spacer()
                }
            }
        )
        .id(item.id)
    }

    private func systemFoldersList() -> some View {
        VStack(spacing: .zero) {
            ForEach(screenModel.state.system) { item in
                SidebarItemButton(
                    item: .system(item),
                    action: { select(item: .system(item)) },
                    content: { systemItemContent(model: item) }
                )
            }
        }
    }

    private func customFoldersList() -> some View {
        VStack(spacing: .zero) {
            ForEach(screenModel.state.folders) { folder in
                SingleFolderNodeView(
                    folder: folder,
                    selected: { folder in select(item: .folder(folder)) },
                    toggle: { folder, expand in screenModel.handle(action: .toggle(folder: folder, expand: expand)) },
                    unreadTextView: { count, isSelected in unreadLabel(unreadCount: count, isSelected: isSelected) }
                )
            }
            createButton(
                for: screenModel.state.createFolder,
                isListEmpty: screenModel.state.folders.isEmpty
            )
        }
    }

    private func labelsList() -> some View {
        VStack(spacing: .zero) {
            ForEach(screenModel.state.labels) { item in
                SidebarItemButton(
                    item: .label(item),
                    action: { select(item: .label(item)) },
                    content: { labelItemContent(model: item) }
                )
            }
            createButton(
                for: screenModel.state.createLabel,
                isListEmpty: screenModel.state.labels.isEmpty
            )
        }
    }

    private func otherItemsList() -> some View {
        VStack(spacing: .zero) {
            ForEach(screenModel.state.other) { item in
                SidebarItemButton(
                    item: .other(item),
                    action: { select(item: .other(item)) },
                    content: { otherItemContent(model: item) }
                )
            }
        }
    }

    private func createButton(for item: SidebarOtherItem, isListEmpty: Bool) -> some View {
        Button(action: { select(item: .other(item)) }) {
            HStack(spacing: .zero) {
                Image(item.icon)
                    .resizable()
                    .renderingMode(.template)
                    .square(size: 20)
                    .tint(DS.Color.Sidebar.iconWeak)
                    .padding(.trailing, DS.Spacing.extraLarge)
                    .accessibilityIdentifier(SidebarScreenIdentifiers.icon)
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(isListEmpty ? DS.Color.Sidebar.textNorm : DS.Color.Sidebar.textWeak)
                    .lineLimit(1)
                    .accessibilityIdentifier(SidebarScreenIdentifiers.textItem)
                Spacer()
            }
        }
        .padding(.vertical, DS.Spacing.medium)
        .padding(.horizontal, DS.Spacing.extraLarge)
        .background(item.isSelected ? DS.Color.Sidebar.interactionPressed : .clear)
        .accessibilityIdentifier(SidebarScreenIdentifiers.otherButton(type: item.type))
    }

    private func systemItemContent(model: SystemFolder) -> some View {
        HStack(spacing: .zero) {
            sidebarItemImage(icon: model.type.icon, isSelected: model.isSelected)
            itemNameLabel(name: model.type.humanReadable.string, isSelected: model.isSelected)
            Spacer()
            if let unreadCount = model.unreadCount {
                unreadLabel(unreadCount: unreadCount, isSelected: model.isSelected)
            }
        }
    }

    private func otherItemContent(model: SidebarOtherItem) -> some View {
        HStack(spacing: .zero) {
            sidebarItemImage(icon: model.icon.image, isSelected: model.isSelected)
            itemNameLabel(name: model.name, isSelected: model.isSelected)
            Spacer()
        }
    }

    private func sidebarItemImage(icon: Image, isSelected: Bool, renderingMode: Image.TemplateRenderingMode = .template) -> some View {
        icon
            .renderingMode(renderingMode)
            .resizable()
            .square(size: 20)
            .tint(isSelected ? DS.Color.Sidebar.iconSelected : DS.Color.Sidebar.iconNorm)
            .padding(.trailing, DS.Spacing.extraLarge)
            .accessibilityIdentifier(SidebarScreenIdentifiers.icon)
    }

    private func labelItemContent(model: SidebarLabel) -> some View {
        HStack(spacing: .zero) {
            Color(hex: model.color)
                .square(size: 12)
                .clipShape(Circle())
                .square(size: 20)
                .padding(.trailing, DS.Spacing.extraLarge)
                .accessibilityElement()
                .accessibilityIdentifier(SidebarScreenIdentifiers.icon)
            itemNameLabel(name: model.name, isSelected: model.isSelected)
            Spacer()
            if let unreadCount = model.unreadCount {
                unreadLabel(unreadCount: unreadCount, isSelected: model.isSelected)
            }
        }
    }

    private func unreadLabel(unreadCount: String, isSelected: Bool) -> some View {
        Text(unreadCount)
            .foregroundStyle(isSelected ? DS.Color.Sidebar.textSelected : DS.Color.Sidebar.textNorm)
            .font(.footnote)
            .fontWeight(.semibold)
            .accessibilityIdentifier(SidebarScreenIdentifiers.badgeIcon)
    }

    private func itemNameLabel(name: String, isSelected: Bool) -> some View {
        Text(name)
            .font(.subheadline)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundStyle(isSelected ? DS.Color.Sidebar.textSelected : DS.Color.Sidebar.textNorm)
            .lineLimit(1)
            .accessibilityIdentifier(SidebarScreenIdentifiers.textItem)
    }

    private var separator: some View {
        Divider()
            .frame(height: 1)
            .background(DS.Color.Sidebar.separator)
    }

    private var appVersionNote: some View {
        Text("Proton Mail \(appVersionProvider.fullVersion)".notLocalized)
            .font(.footnote)
            .foregroundStyle(DS.Color.Sidebar.textWeak)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.jumbo)
            .padding(.bottom, DS.Spacing.extraLarge)
    }

    private func select(item: SidebarItem) {
        screenModel.handle(action: .select(item: item))
        selectedItem(item)
        appUIStateStore.toggleSidebar(isOpen: !item.hideSidebar)
    }

    private func handleDeepLink(_ deepLink: URL) {
        switch DeepLinkRouteCoder.decode(deepLink: deepLink) {
        case .mailbox(.systemFolder(_, let systemFolder)):
            if let systemFolder = screenModel.state.system.first(where: { $0.type == systemFolder }) {
                let item = SidebarItem.system(systemFolder)
                screenModel.handle(action: .select(item: item))
            }
        default:
            break
        }
    }
}

private struct SidebarScreenIdentifiers {
    static let rootItem = "sidebar.rootItem"
    static let icon = "sidebar.button.icon"
    static let textItem = "sidebar.button.text"
    static let badgeIcon = "sidebar.button.badgeIcon"

    static func otherButton(type: SidebarOtherItem.ItemType) -> String {
        "sidebar.button.\(type.rawValue)"
    }
}

private extension SidebarItem {

    var hideSidebar: Bool {
        switch self {
        case .upsell, .system, .label, .folder:
            true
        case .other(let item):
            item.hideSidebar
        }
    }

}

private extension SidebarOtherItem {

    var hideSidebar: Bool {
        switch type {
        case .createFolder, .createLabel, .settings:
            true
        case .shareLogs, .contacts, .bugReport, .subscriptions:
            false
        }
    }

}
