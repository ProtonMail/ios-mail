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
    @State private var screenModel = SidebarScreenModel()

    //    init(screenModel: SidebarScreenModel) {
    //        self.screenModel = screenModel
    //    }

    private let animation: Animation = .easeInOut(duration: 0.2)

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

                VStack(spacing: 24) {
                    ForEach(screenModel.systemFolders) { systemFolder in
                        SidebarCell(uiModel: systemFolder)
                    }
                }
                .padding(.init(top: 24.0, leading: 16.0, bottom: 24.0, trailing: 16.0))
            }
            Spacer()
        }
        .background(DS.Color.sidebarBackground)
    }
}

import proton_mail_uniffi

struct SidebarCellUIModel: Identifiable {
    let id: LocalLabelId
    let name: String
    let icon: UIImage
    let badge: String
    let route: Route
}

struct SidebarCell: View {
    @Environment(\.navigate) var navigate
    let uiModel: SidebarCellUIModel

    var body: some View {

        Button(action: {
            navigate(uiModel.route)
        }, label: {
            HStack {

                Image(uiImage: uiModel.icon)
                    .renderingMode(.template)
                    .foregroundColor(DS.Color.sidebarTextNorm)
                Text(uiModel.name)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.sidebarTextNorm)
                    .padding(.leading, 16)
                Spacer()
                Text(uiModel.badge)
                    .foregroundStyle(DS.Color.sidebarTextNorm)
                    .opacity(uiModel.badge.isEmpty ? 0 : 1)
            }
        })
    }
}

#Preview {
    let appUIState = AppUIState(isSidebarOpen: true, selectedMailbox: nil)
    struct PreviewWrapper: View {

        var body: some View {
            SidebarScreen()
//            SidebarScreen(screenModel: PreviewData.sideBarScreenModel)
        }
    }
    return PreviewWrapper().environmentObject(appUIState)
}
