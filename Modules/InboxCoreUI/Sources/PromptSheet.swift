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

import InboxCore
import InboxDesignSystem
import SwiftUI

public struct PromptSheet: View {
    private let image: ImageResource
    private let title: LocalizedStringResource
    private let subtitle: LocalizedStringResource
    private let actionButtonTitle: LocalizedStringResource
    private let onAction: () -> Void
    private let onDismiss: () -> Void

    @State private var bodyHeight: CGFloat = 0

    public init(
        image: ImageResource,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        actionButtonTitle: LocalizedStringResource,
        onAction: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.actionButtonTitle = actionButtonTitle
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    // MARK: - View

    public var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            Image(image)

            Spacer().frame(height: DS.Spacing.standard)

            Text(title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(DS.Color.Text.norm)

            Spacer().frame(height: DS.Spacing.compact)

            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: DS.Spacing.jumbo)

            Button(action: onAction) {
                Text(actionButtonTitle)
            }
            .buttonStyle(BigButtonStyle())

            Spacer().frame(height: DS.Spacing.extraLarge)

            Button(CommonL10n.dismiss.string) {
                onDismiss()
            }
            .buttonStyle(SmallButtonStyle())
        }
        .presentationDetents([.height(bodyHeight)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .presentationCornerRadius(DS.Radius.extraLarge)
        .padding(.horizontal, DS.Spacing.extraLarge)
        .padding(.top, DS.Spacing.huge + DS.Spacing.extraLarge)
        .padding(.bottom, DS.Spacing.extraLarge)
        .background(DS.Color.Background.norm)
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { newValue in
            bodyHeight = newValue
        }
    }
}
