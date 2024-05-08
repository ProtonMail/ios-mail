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
    @State private var screenModel: SidebarScreenModel

    private let animation: Animation = .easeInOut(duration: 0.2)

    init(screenModel: SidebarScreenModel) {
        self.screenModel = screenModel
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                translucidBackground
                sidebarContent
                    .frame(width: geometry.size.width * 0.9)
                    .frame(maxHeight: .infinity)
                    .offset(x: appUIState.isSidebarOpen ? 0 : -geometry.size.width)
                    .animation(animation, value: appUIState.isSidebarOpen)
            }
        }
        .task {
            await screenModel.onViewWillAppear()
        }
    }

    var translucidBackground: some View {
        GeometryReader { _ in
            EmptyView()
        }
        .background(.black.opacity(0.6))
        .opacity(appUIState.isSidebarOpen ? 1 : 0)
        .animation(animation, value: appUIState.isSidebarOpen)
        .onTapGesture {
            appUIState.isSidebarOpen = false
        }
        .edgesIgnoringSafeArea(.all)
    }

    var sidebarContent: some View {
        HStack {
            ZStack {

            }
            .frame(width: 56)
            .frame(maxHeight: .infinity)

            ScrollView(showsIndicators: false) {
                foldersAndLabelsView
                appVersionView
            }
            Spacer()
        }
        .background(DS.Color.Sidebar.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SidebarScreenIdentifiers.rootElement)
    }

    var foldersAndLabelsView: some View {
        VStack(spacing: 24) {
            ForEach(screenModel.systemFolders) { systemFolder in
                SidebarCell(
                    uiModel: systemFolder,
                    isSelected: systemFolder.id == screenModel.route.localLabelId
                ) {
                    screenModel.updateRoute(newRoute: systemFolder.route)
                    appUIState.isSidebarOpen = false
                }
            }
        }
        .padding(.init(top: 24.0, leading: 16.0, bottom: 24.0, trailing: 16.0))
    }

    var appVersionView: some View {
        VStack {
//            // temporary hacky share logs cell
            SidebarCell(uiModel: .init(id: UInt64.max, name: "[DEV] Share logs", icon: DS.Icon.icBug , badge: "", route: .appLaunching), isSelected: false) {
                screenModel.onShareLogsTap()
            }
            .padding(.init(top: 24.0, leading: 16.0, bottom: 24.0, trailing: 16.0))

            Divider()
                .background(DS.Color.Global.white)
            Spacer()
            Text("Proton Mail \(Bundle.main.appVersion)")
                .font(.footnote)
                .foregroundStyle(DS.Color.Sidebar.textNorm)
        }
    }
}

struct SidebarCellUIModel: Identifiable {
    let id: PMLocalLabelId
    let name: String
    let icon: UIImage
    let badge: String
    let route: Route
}

struct SidebarCell: View {
    private let uiModel: SidebarCellUIModel
    private let isSelected: Bool
    private var onSelection: () -> Void

    init(uiModel: SidebarCellUIModel, isSelected: Bool, onSelection: @escaping () -> Void) {
        self.uiModel = uiModel
        self.isSelected = isSelected
        self.onSelection = onSelection
    }

    var textColor: Color {
        isSelected ? DS.Color.Sidebar.textWeak : DS.Color.Sidebar.textNorm
    }

    var body: some View {

        Button(action: {
            onSelection()
        }, label: {
            HStack {

                Image(uiImage: uiModel.icon)
                    .renderingMode(.template)
                    .foregroundColor(textColor)
                Text(uiModel.name)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundStyle(textColor)
                    .padding(.leading, 16)
                Spacer()
                Text(uiModel.badge)
                    .foregroundStyle(textColor)
                    .opacity(uiModel.badge.isEmpty ? 0 : 1)
            }
        })
    }
}

#Preview {
    let appUIState = AppUIState(isSidebarOpen: true)
    let route: AppRouteState = .init(route: .mailbox(label: .placeHolderMailbox))

    struct PreviewWrapper: View {
        @State var appRoute: AppRouteState

        var body: some View {
            SidebarScreen(screenModel: .init(appRoute: appRoute, systemFolders: PreviewData.systemFolders))
        }
    }
    return PreviewWrapper(appRoute: route).environmentObject(appUIState)
}

private struct SidebarScreenIdentifiers {
    static let rootElement = "sidebar.rootElement"
}
