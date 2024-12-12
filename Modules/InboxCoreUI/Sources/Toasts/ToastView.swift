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

import InboxDesignSystem
import SwiftUI

public struct ToastView: View {
    let model: Toast
    let didSwipeDown: () -> Void

    public init(model: Toast, didSwipeDown: @escaping () -> Void) {
        self.model = model
        self.didSwipeDown = didSwipeDown
    }

    public var body: some View {
        VStack {
            switch model.button {
            case .none:
                textsView()
            case .some(let button):
                switch button.type {
                case .largeBottom(let buttonTitle):
                    VStack(spacing: DS.Spacing.moderatelyLarge) {
                        textsView()
                        largeTitleButton(title: buttonTitle, action: button.action)
                    }
                case .smallTrailing(let buttonType):
                    HStack(spacing: DS.Spacing.moderatelyLarge) {
                        textsView()

                        switch buttonType {
                        case .image(let imageResource):
                            smallImageButton(imageResource: imageResource, action: button.action)
                        case .title(let title):
                            smallTitleButton(title: title, action: button.action)
                        }
                    }
                }
            }
        }
        .padding(.init(vertical: DS.Spacing.moderatelyLarge, horizontal: DS.Spacing.large))
        .background(model.style.color, in: RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        .safeAreaPadding(.horizontal, DS.Spacing.large)
        .safeAreaPadding(.bottom, DS.Spacing.large)
        .shadow(color: DS.Color.Global.black.opacity(model.shadowOpacity), radius: 20)
        .swipe(down: { didSwipeDown() })
    }

    // MARK: - Private

    private func textsView() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            if let title = model.title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(DS.Color.Text.inverted)
                    .lineLimit(1)
            }
            Text(model.message)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.inverted)
                .lineLimit(7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func smallImageButton(imageResource: ImageResource, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                Image(imageResource)
                    .padding(DS.Spacing.standard)
                    .foregroundColor(DS.Color.Text.inverted)
                    .background(DS.Color.Global.white.opacity(0.2), in: Circle())
            }
        )
    }

    private func smallTitleButton(title: String, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.inverted)
                    .padding(.init(vertical: DS.Spacing.standard, horizontal: DS.Spacing.large))
                    .background(DS.Color.Global.white.opacity(0.2), in: Capsule())
            }
        )
    }

    private func largeTitleButton(title: String, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.inverted)
                    .frame(maxWidth: .infinity)
                    .padding(.init(vertical: DS.Spacing.medium, horizontal: DS.Spacing.large))
                    .background(DS.Color.Global.white.opacity(0.2), in: Capsule())
            }
        )
    }
}

enum ToastViewPreviewProvider {

    // MARK: - Models

    static var smallWarningShortTextNoAction: Toast {
        testToast(
            title: nil,
            message: "Short text with no action button",
            button: .none,
            style: .warning
        )
    }

    static var smallErrorLongTextNoAction: Toast {
        testToast(
            title: nil,
            message: "Longer system message with the icon action button.",
            button: .none,
            style: .error
        )
    }

    static var smallInformationLongTextWithButton: Toast {
        testToast(
            title: nil,
            message: "Longer system message with the icon action button.",
            button: .init(type: .smallTrailing(content: .image(DS.Icon.icArrowRotateRight)), action: {}),
            style: .information
        )
    }

    static var smallSuccessLongTextWithButton: Toast {
        testToast(
            title: nil,
            message: "Longer system message with the text action button.",
            button: .init(type: .smallTrailing(content: .title("Action")), action: {}),
            style: .success
        )
    }

    static var bigErrorShortTextWithButton: Toast {
        testToast(
            title: "Oops!",
            message: "There was an issue while sending your email.",
            button: .init(type: .largeBottom(buttonTitle: "Action"), action: {}),
            style: .error
        )
    }

    static var bigWarningShortTextWithButton: Toast {
        testToast(
            title: "Oops!",
            message: "There was an issue while sending your email.",
            button: .init(type: .largeBottom(buttonTitle: "Action"), action: {}),
            style: .warning
        )
    }

    static var bigSuccessLongTextWithButton: Toast {
        testToast(
            title: "Hurray!",
            message: "It seems that there was no issue while sending your email. We apologize for the inconvenience. Our team is working diligently to resolve this problem.",
            button: .init(type: .largeBottom(buttonTitle: "Action"), action: {}),
            style: .success
        )
    }

    static var bigErrorMaxLongTextWithButton: Toast {
        testToast(
            title: nil,
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?",
            button: .init(type: .largeBottom(buttonTitle: "Action"), action: {}),
            style: .error
        )
    }

    private static func testToast(title: String?, message: String, button: Toast.Button?, style: Toast.Style) -> Toast {
        .init(title: title, message: message, button: button, style: style, duration: 4)
    }

}

#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        VStack {
            ToastView(model: ToastViewPreviewProvider.smallWarningShortTextNoAction, didSwipeDown: {})
            ToastView(model: ToastViewPreviewProvider.smallErrorLongTextNoAction, didSwipeDown: {})
            ToastView(model: ToastViewPreviewProvider.smallInformationLongTextWithButton, didSwipeDown: {})
            ToastView(model: ToastViewPreviewProvider.smallSuccessLongTextWithButton, didSwipeDown: {})
            ToastView(model: ToastViewPreviewProvider.bigErrorShortTextWithButton, didSwipeDown: {})
            ToastView(model: ToastViewPreviewProvider.bigSuccessLongTextWithButton, didSwipeDown: {})
            ToastView(model: ToastViewPreviewProvider.bigErrorMaxLongTextWithButton, didSwipeDown: {})
        }
    }
}

private extension View {
    func swipe(down: @escaping (() -> Void)) -> some View {
        gesture(
            DragGesture(minimumDistance: .zero, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.height > 0 { down() }
                }
        )
    }
}
