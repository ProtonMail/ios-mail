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

import InboxDesignSystem
import SwiftUI

public struct LongPressFormBigButton: View {
    private let title: LocalizedStringResource
    private let value: String
    private let hasAccentTextColor: Bool
    private let onTap: () -> Void
    private let longPressActions: () -> [UIAction]
    @State private var isPressed: Bool = false
    @State private var isEditMenuPresent: Bool = false

    public init(
        title: LocalizedStringResource,
        value: String,
        hasAccentTextColor: Bool,
        onTap: @escaping () -> Void,
        longPressActions: @escaping () -> [UIAction]
    ) {
        self.title = title
        self.value = value
        self.hasAccentTextColor = hasAccentTextColor
        self.onTap = onTap
        self.longPressActions = longPressActions
    }

    public var body: some View {
        FormBigButtonContent(
            title: title,
            value: value,
            hasAccentTextColor: hasAccentTextColor,
            symbol: .none
        )
        .editMenu(
            actions: longPressActions,
            onPresent: { isEditMenuPresent = true },
            onDismiss: { isEditMenuPresent = false }
        )
        .onLongPressGesture(perform: {}, onPressingChanged: { changed in isPressed = changed })
        .onTapGesture(perform: onTap)
        .background(isPressed || isEditMenuPresent ? DS.Color.InteractionWeak.pressed : .clear)
        .background(DS.Color.BackgroundInverted.secondary)
    }
}

private extension View {
    func editMenu(
        actions: @escaping () -> [UIAction],
        onPresent: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        overlay {
            EditMenu(
                content: self,
                actions: actions,
                onPresent: onPresent,
                onDismiss: onDismiss
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct EditMenu<Content: View>: UIViewRepresentable {
    let content: Content
    let actions: () -> [UIAction]
    let onPresent: (() -> Void)?
    let onDismiss: (() -> Void)?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> UIView {
        if let interaction = context.coordinator.interaction {
            context.coordinator.uiView.addInteraction(interaction)
        }

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        context.coordinator.uiView.addGestureRecognizer(longPress)

        return context.coordinator.uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        coordinator.interaction = UIEditMenuInteraction(delegate: coordinator)
        return coordinator
    }

    class Coordinator: NSObject, UIEditMenuInteractionDelegate {
        let editMenu: EditMenu
        let uiView = UIView()

        var interaction: UIEditMenuInteraction?
        private var isPresent = false

        init(_ editMenu: EditMenu) {
            self.editMenu = editMenu
        }

        @objc
        func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
            guard isPresent == false, gestureRecognizer.state == .began else { return }

            let point = CGPoint(x: uiView.bounds.midX, y: 0)
            let configuration = UIEditMenuConfiguration(identifier: nil, sourcePoint: point)
            interaction?.presentEditMenu(with: configuration)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        // MARK: - UIEditMenuInteractionDelegate

        func editMenuInteraction(
            _ interaction: UIEditMenuInteraction,
            menuFor configuration: UIEditMenuConfiguration,
            suggestedActions: [UIMenuElement]
        ) -> UIMenu? {
            let customMenu = UIMenu(options: .displayInline, children: editMenu.actions())
            return UIMenu(children: customMenu.children)
        }

        func editMenuInteraction(
            _ interaction: UIEditMenuInteraction,
            willPresentMenuFor configuration: UIEditMenuConfiguration,
            animator: UIEditMenuInteractionAnimating
        ) {
            editMenu.onPresent?()
            isPresent = true
        }

        func editMenuInteraction(
            _ interaction: UIEditMenuInteraction,
            willDismissMenuFor configuration: UIEditMenuConfiguration,
            animator: UIEditMenuInteractionAnimating
        ) {
            editMenu.onDismiss?()
            isPresent = false
        }
    }
}
