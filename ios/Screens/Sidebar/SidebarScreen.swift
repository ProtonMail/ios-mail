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
    @State private var model: SidebarScreenModel
    @EnvironmentObject private var appUIState: AppUIState

    init(model: SidebarScreenModel) {
        self.model = model
    }

    private let animation: Animation = .easeInOut(duration: 0.2)

    var body: some View {
        ZStack {
            GeometryReader { _ in
                EmptyView()
            }
            .background(.black.opacity(0.6))
            .opacity(appUIState.isSidebarOpen ? 1 : 0)
            .animation(animation, value: appUIState.isSidebarOpen)
            .onTapGesture {
                appUIState.isSidebarOpen.toggle()
            }
            .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                sidebarContent
                    .frame(width: geometry.size.width * 0.8)
                    .padding(.init(top: 24.0, leading: 20.0, bottom: 24.0, trailing: 20.0))
                    .background()
                    .offset(x: appUIState.isSidebarOpen ? 0 : -geometry.size.width)
                    .animation(animation, value: appUIState.isSidebarOpen)
            }
        }
    }

    var sidebarContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                ForEach(model.items) { item in
                    SidebarCell(icon: item.icon, text: item.text, badge: item.badge)
                }
                Spacer()
            }
        }
    }
}

struct SidebarCell: View {
    let icon: UIImage
    let text: String
    let badge: String?

    var body: some View {
        HStack {
            Image(uiImage: icon)
            Text(text)
            Spacer()
            Circle()
                .frame(width: 24, height: 24)
                .foregroundColor(.purple)
                .overlay {
                    Text(badge ?? "")
                }
                .opacity(badge == nil ? 0 : 1)
        }
    }
}

#Preview {
    let appUIState = AppUIState(isSidebarOpen: true)
    struct PreviewWrapper: View {

        var body: some View {
            SidebarScreen(model: PreviewData.sidebarScreenModel)
        }
    }
    return PreviewWrapper().environmentObject(appUIState)
}
