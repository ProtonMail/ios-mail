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
import proton_app_uniffi
import SwiftUI

struct ContactActionButton: View {
    let image: ImageResource
    let title: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.standard) {
                Image(image)
                    .square(size: 24)
                    .foregroundStyle(foregroundColor)
                Text(title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.large)
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .buttonStyle(DefaultButtonStyle())
        .cornerRadius(DS.Radius.large, corners: .allCorners)
        .disabled(disabled)
    }

    // MARK: - Private

    private var foregroundColor: Color {
        disabled ? DS.Color.Text.disabled : DS.Color.Text.weak
    }
}

// FIXME: Extract SettingsButtonStyle to InboxCoreUI
struct DefaultButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .background(configuration.isPressed ? DS.Color.InteractionWeak.pressed : .clear)
    }

}

struct ContactDetails {
    let id: Id
    let avatarInformation: AvatarInformation
    let displayName: String
    let primaryEmail: String
    let primaryPhone: String?
    let groupItems: [[ContactDetailItem]]
}

struct ContactDetailItem: Hashable {
    let label: String
    let value: String
    let isInteractive: Bool
}

struct ContactDetailsScreen: View {
    let model: ContactDetails

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    ZStack {
                        Rectangle()
                            .fill(Color(hex: model.avatarInformation.color))
                            .square(size: 100)
                            .cornerRadius(DS.Radius.giant, corners: .allCorners)
                        Text(model.avatarInformation.text)
                            .font(.title)
                            .fontWeight(.regular)
                            .foregroundStyle(DS.Color.Text.inverted)
                    }

                    VStack(spacing: DS.Spacing.compact) {
                        Text(model.displayName)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.Text.norm)
                        Text(model.primaryEmail)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundStyle(DS.Color.Text.weak)
                    }

                    HStack(spacing: DS.Spacing.standard) {
                        ContactActionButton(
                            image: DS.Icon.icPenSquare,
                            title: "Message",
                            disabled: false,
                            action: { print(">>> message") }
                        )
                        ContactActionButton(
                            image: DS.Icon.icPhone,
                            title: "Call",
                            disabled: model.primaryPhone == nil,
                            action: { print(">>> call") }
                        )
                        ContactActionButton(
                            image: DS.Icon.icArrowUpFromSquare,
                            title: "Share",
                            disabled: false,
                            action: { print(">>> share") }
                        )
                    }
                    ForEach(model.groupItems, id: \.self) { items in
                        ContactDetailsGroup(items: items)
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
        }
    }
}

struct ContactDetailsScreen_Previews: PreviewProvider {
    static var previews: some View {
        let groupItems: [[ContactDetailItem]] = [
            [
                .init(label: "Work", value: "ben.ale@protonmail.com", isInteractive: true),
                .init(label: "Private", value: "alexander@proton.me", isInteractive: true),
            ],
            [
                .init(label: "Home", value: "+370 (637) 98 998", isInteractive: true),
                .init(label: "Work", value: "+370 (637) 98 999", isInteractive: true),
            ],
            [
                .init(label: "Address", value: "Lettensteg 10, 8037 Zurich", isInteractive: true)
            ],
            [
                .init(label: "Birthday", value: "Dec 09, 2006", isInteractive: false)
            ],
            [
                .init(
                    label: "Note",
                    value: "Met Caleb while studying abroad. Amazing memories and a strong friendship.",
                    isInteractive: false
                )
            ]
        ]

        ContactDetailsScreen(
            model: .init(
                id: .init(value: 50),
                avatarInformation: .init(text: "BA", color: "#3357FF"),
                displayName: "Benjamin Alexander",
                primaryEmail: "ben.ale@protonmail.com",
                primaryPhone: .none,
                groupItems: groupItems
            )
        )
    }
}

struct ContactDetailsGroup: View {
    let items: [ContactDetailItem]

    var body: some View {
        LazyVStack(spacing: .zero) {
            ForEachLast(collection: items) { item, isLast in
                VStack(spacing: .zero) {
                    ContactDetailsItem(model: item)

                    if !isLast {
                        DS.Color.BackgroundInverted.border.frame(height: 1)
                    }
                }
            }
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .cornerRadius(DS.Radius.extraLarge, corners: .allCorners)
    }
}

// FIXME: Replace with FormBigButton
struct ContactDetailsItem: View {
    let model: ContactDetailItem

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            Text(model.label)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundColor(DS.Color.Text.weak)
            Text(model.value)
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(model.isInteractive ? DS.Color.Text.accent : DS.Color.Text.norm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.large)
    }
}

// FIXME: To remove
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    init(radius: CGFloat = .infinity, corners: UIRectCorner = .allCorners) {
        self.radius = radius
        self.corners = corners
    }

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
