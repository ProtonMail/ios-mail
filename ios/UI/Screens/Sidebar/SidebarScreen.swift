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

import DesignSystem
import SwiftUI

struct SidebarScreen: View {
    @EnvironmentObject private var appUIState: AppUIState
    @Environment(\.mainBundle) var mainBundle: Bundle
    @State private var screenModel: SidebarModel
    @State private var headerHeight: CGFloat = .zero
    private let sidebarWidth: CGFloat = 320
    private let widthOfDragableSpaceOnTheMailbox: CGFloat = 35
    private let animationDuration = 0.2
    private let selectedItem: (SidebarItem) -> Void

    private var dragOffset: CGFloat {
        appUIState.isSidebarOpen ? sidebarWidth : .zero
    }

    init(screenModel: SidebarModel = .init(), selectedItem: @escaping (SidebarItem) -> Void) {
        self.screenModel = screenModel
        self.selectedItem = selectedItem
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                opacityBackground
                    .gesture(closeSidebarTapGesture)
                    .frame(width: 2 * geometry.size.width)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: sidebarWidth + geometry.safeAreaInsets.leading + widthOfDragableSpaceOnTheMailbox)
                    .gesture(sidebarDragGesture)
                    .gesture(appUIState.isSidebarOpen ? closeSidebarTapGesture : nil)

                HStack(spacing: 0) {
                    sideBarBackground
                        .frame(width: geometry.safeAreaInsets.leading)
                    ZStack(alignment: .topLeading) {
                        sideBarBackground
                        sideBarItemsList
                            .safeAreaPadding(.top, headerHeight)
                            .padding(.top, DS.Spacing.standard)
                        header
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SidebarScreenIdentifiers.rootItem)
                }
                .frame(width: sidebarWidth)
                .highPriorityGesture(sidebarDragGesture)
            }
            .animation(.easeOut(duration: animationDuration), value: appUIState.isSidebarOpen)
            .offset(x: dragOffset - sidebarWidth - geometry.safeAreaInsets.leading)
        }
        .onAppear { screenModel.handle(action: .viewAppear) }
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Image(DS.Images.mailProductLogo)
                .padding(.leading, DS.Spacing.extraLarge)
                .padding(.vertical, DS.Spacing.small)
            separator
        }.background(
            GeometryReader { geometry in
                TransparentBlur()
                    .edgesIgnoringSafeArea(.all)
                    .preference(key: HeaderHeightPreferenceKey.self, value: geometry.size.height)
                    .onPreferenceChange(HeaderHeightPreferenceKey.self) { value in
                        headerHeight = value
                    }
            }
        )
    }

    private var sidebarDragGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                appUIState.isSidebarOpen = value.velocity.width > 100
            }
    }

    private var closeSidebarTapGesture: some Gesture {
        TapGesture()
            .onEnded { appUIState.isSidebarOpen = false }
    }

    private var opacityBackground: some View {
        DS.Color.Sidebar.overlay
            .animation(.linear(duration: animationDuration), value: appUIState.isSidebarOpen)
            .opacity(0.5 * (dragOffset / sidebarWidth))
            .ignoresSafeArea(.all)
    }

    private var sideBarBackground: some View {
        DS.Color.Sidebar.background
            .edgesIgnoringSafeArea(.all)
    }

    private var sideBarItemsList: some View {
        VStack(alignment: .leading, spacing: .zero) {
            ScrollViewReader { proxy in
                ScrollView {
                    list(for: screenModel.state.system.map(SidebarItem.system))
                    separator
                    FolderNodeView(folders: screenModel.state.folders.sidebarFolderNodes) { folder in
                        select(item: .folder(folder))
                    }
                    createButton(
                        for: screenModel.state.createFolder,
                        isListEmpty: screenModel.state.folders.isEmpty
                    )
                    separator
                    list(for: screenModel.state.labels.map(SidebarItem.label))
                    createButton(
                        for: screenModel.state.createLabel,
                        isListEmpty: screenModel.state.labels.isEmpty
                    )
                    separator
                    list(for: screenModel.state.other.map(SidebarItem.other))
                    separator
                    appVersionNote
                }.onChange(of: appUIState.isSidebarOpen) { _, isSidebarOpen in
                    if isSidebarOpen, let first = screenModel.state.system.first {
                        proxy.scrollTo("\(first.localID)", anchor: .zero)
                    }
                }.accessibilityElement(children: .contain)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func list(for items: [SidebarItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                sidebarItemButton(for: item)
            }
        }
    }

    private func sidebarItemButton(for item: SidebarItem) -> some View {
        Button(action: { select(item: item) }) {
            switch item {
            case .system(let model):
                systemItemContent(model: model)
            case .label(let model):
                labelItemContent(model: model)
            case .folder(let model):
                labelItemContent(model: .init(
                    localID: model.id,
                    color: model.color,
                    name: model.name,
                    unreadCount: model.unreadCount == 0 ? nil : model.unreadCount.toBadgeCapped(),
                    isSelected: model.isSelected
                )) // FIXME: -
            case .other(let model):
                otherItemCotent(model: model)
            }
        }
        .padding(.vertical, DS.Spacing.medium)
        .padding(.horizontal, DS.Spacing.extraLarge)
        .background(item.isSelected ? DS.Color.Sidebar.interactionPressed : .clear)
    }

    private func createButton(for item: SidebarOtherItem, isListEmpty: Bool) -> some View {
        Button(action: { select(item: .other(item)) }) {
            HStack {
                Image(item.icon)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 20, height: 20)
                    .tint(DS.Color.Sidebar.iconWeak)
                    .padding(.trailing, DS.Spacing.extraLarge)
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(isListEmpty ? DS.Color.Sidebar.textNorm : DS.Color.Sidebar.textWeak)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.vertical, DS.Spacing.medium)
        .padding(.horizontal, DS.Spacing.extraLarge)
        .background(item.isSelected ? DS.Color.Sidebar.interactionPressed : .clear)
    }

    private func systemItemContent(model: SidebarSystemFolder) -> some View {
        HStack {
            sidebarItemImage(icon: model.identifier.icon, isSelected: model.isSelected)
            itemNameLabel(name: model.identifier.humanReadable.string, isSelected: model.isSelected)
            Spacer()
            if let unreadCount = model.unreadCount {
                unreadLabel(unreadCount: unreadCount, isSelected: model.isSelected)
            }
        }
    }

    private func otherItemCotent(model: SidebarOtherItem) -> some View {
        HStack {
            sidebarItemImage(icon: model.icon, isSelected: model.isSelected)
            itemNameLabel(name: model.name, isSelected: model.isSelected)
            Spacer()
        }
    }

    private func sidebarItemImage(icon: ImageResource, isSelected: Bool) -> some View {
        Image(icon)
            .renderingMode(.template)
            .square(size: 20)
            .tint(isSelected ? DS.Color.Sidebar.iconSelected : DS.Color.Sidebar.iconNorm)
            .padding(.trailing, DS.Spacing.extraLarge)
            .accessibilityIdentifier(SidebarScreenIdentifiers.folderIcon)
    }

    private func labelItemContent(model: SidebarLabel) -> some View {
        HStack {
            Color(hex: model.color)
                .square(size: 13)
                .clipShape(Circle())
                .square(size: 20)
                .padding(.trailing, DS.Spacing.extraLarge)
            itemNameLabel(name: model.name, isSelected: model.isSelected)
            Spacer()
            if let unreadCount = model.unreadCount {
                unreadLabel(unreadCount: unreadCount, isSelected: model.isSelected)
            }
        }
    }

    private func unreadLabel(unreadCount: String, isSelected: Bool) -> some View {
        Text(unreadCount)
            .foregroundStyle(isSelected ? DS.Color.Sidebar.textNorm : DS.Color.Sidebar.textWeak)
            .font(.caption)
            .accessibilityIdentifier(SidebarScreenIdentifiers.badgeIcon)
    }

    private func itemNameLabel(name: String, isSelected: Bool) -> some View {
        Text(name)
            .font(.subheadline)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundStyle(isSelected ? DS.Color.Sidebar.textSelected : DS.Color.Sidebar.textNorm)
            .lineLimit(1)
            .accessibilityIdentifier(SidebarScreenIdentifiers.labelText)
    }

    private var separator: some View {
        Divider()
            .frame(height: 1)
            .background(DS.Color.Sidebar.separator)
    }

    private var appVersionNote: some View {
        Text("Version number \(mainBundle.appVersion)".notLocalized)
            .font(.footnote)
            .foregroundStyle(DS.Color.Sidebar.textWeak)
            .padding(.top, DS.Spacing.jumbo)
            .padding(.bottom, DS.Spacing.extraLarge)
    }

    private func closeSidebarAction() {
        appUIState.isSidebarOpen = false
    }

    private func select(item: SidebarItem) {
        screenModel.handle(action: .select(item: item))
        selectedItem(item)

        switch item {

        case .other(let sidebarOtherItem):
            switch sidebarOtherItem.type {
            case .subscriptions, .createLabel, .createFolder:
                appUIState.isSidebarOpen = false
            default:
                break
            }
        default:
            appUIState.isSidebarOpen = !item.isSelectable
        }

        if item.isShareLogsItem {
            onShareLogsTap()
        }
    }

    private func onShareLogsTap() {
        let fileManager = FileManager.default
        guard let logFolder = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let sourceLogFile = logFolder.appending(path: "proton-mail-uniffi.log")
        let activityVC = UIActivityViewController(activityItems: [sourceLogFile], applicationActivities: nil)
        UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true)
    }

}

private struct SidebarScreenIdentifiers {
    static let rootItem = "sidebar.rootItem"
    static let folderIcon = "sidebar.button.folderIcon"
    static let labelText = "sidebar.button.labelText"
    static let badgeIcon = "sidebar.button.badgeIcon"
}

private struct HeaderHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension SidebarItem {

    var isShareLogsItem: Bool {
        guard case .other(let otherItem) = self else {
            return false
        }
        return otherItem.type == .shareLogs
    }

}
