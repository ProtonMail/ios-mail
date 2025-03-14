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

import InboxCore
import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

struct MessageBodyAttachmentsView: View {
    @State private var state: MessageBodyAttachmentsState
    @Binding var attachmentIDToOpen: ID?

    /// Convenience initializer that exposes `state` for testing purposes, allowing simulation of different states (e.g., an expanded attachments list).
    init(state: MessageBodyAttachmentsState, attachmentIDToOpen: Binding<ID?>) {
        self.state = state
        self._attachmentIDToOpen = attachmentIDToOpen
    }

    init(attachments: [AttachmentDisplayModel], attachmentIDToOpen: Binding<ID?>) {
        self.init(state: .state(attachments: attachments), attachmentIDToOpen: attachmentIDToOpen)
    }

    var body: some View {
        makeBody()
            .padding(.top, DS.Spacing.extraLarge)
            .padding([.horizontal, .bottom], DS.Spacing.large)
    }

    // MARK: - Private
    
    @ViewBuilder
    private func makeBody() -> some View {
        switch state.listState {
        case .short:
            attachmentsList()
        case .long(let isAttachmentsListOpen):
            expandableAttachmentsList(isAttachmentsListOpen: isAttachmentsListOpen)
        }
    }

    private func expandableAttachmentsList(isAttachmentsListOpen: Bool) -> some View {
        VStack(spacing: DS.Spacing.standard) {
            attachmentsCountRow(isAttachmentsListOpen: isAttachmentsListOpen)
            if isAttachmentsListOpen {
                attachmentsList()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(-1)
            }
        }
        .clipped()
    }

    private func attachmentsList() -> some View {
        VStack(spacing: DS.Spacing.standard) {
            ForEach(state.attachments, id: \.self) { attachment in
                attachmentButton(attachment: attachment)
            }
        }
    }

    private func attachmentsCountRow(isAttachmentsListOpen: Bool) -> some View {
        button(action: {
            withAnimation {
                state = state.copy(\.listState, to: .long(isAttachmentsListOpen: !isAttachmentsListOpen))
            }
        }) {
            HStack(spacing: .zero) {
                Image(DS.Icon.icPaperClip)
                    .resizable()
                    .square(size: 20)
                    .foregroundStyle(DS.Color.Icon.weak)
                    .padding(.trailing, DS.Spacing.medium)
                Text(attachmentsCount)
                Spacer()
                Text(state.attachments.totalSizeDescription)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.hint)
                    .padding(.trailing, DS.Spacing.mediumLight)
                Image(DS.Icon.icChevronTinyDown)
                    .resizable()
                    .square(size: 20)
                    .rotationEffect(.degrees(isAttachmentsListOpen ? -180 : .zero))
                    .animation(.easeInOut, value: isAttachmentsListOpen)
                    .foregroundStyle(DS.Color.Icon.weak)
            }
        }
    }

    private func attachmentButton(attachment: AttachmentDisplayModel) -> some View {
        button(action: { attachmentIDToOpen = attachment.id }) {
            HStack(spacing: .zero) {
                Image(attachment.mimeType.category.bigIcon)
                    .resizable()
                    .square(size: 20)
                    .padding(.trailing, DS.Spacing.medium)
                Text(attachment.name)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
                Spacer()
                Text(attachment.displaySize)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.hint)
            }
        }
    }

    private func button<Content: View>(action: @escaping () -> Void, content: () -> Content) -> some View {
        Button(action: { action() }) {
            content()
                .padding(.vertical, DS.Spacing.mediumLight)
                .padding(.leading, DS.Spacing.medium)
                .padding(.trailing, DS.Spacing.large)
        }
        .background(DS.Color.InteractionWeak.norm)
        .clipShape(Capsule())
    }

    private var attachmentsCount: AttributedString {
        var attributedString = AttributedString(
            localized: L10n.MessageDetails.attachments(count: state.attachments.count)
        )
        attributedString.font = .footnote
        attributedString.foregroundColor = DS.Color.Text.weak
        let numberRange = attributedString.range(of: "\(state.attachments.count)").unsafelyUnwrapped
        attributedString[numberRange].font = .system(Font.TextStyle.footnote, weight: .bold)
        attributedString[numberRange].foregroundColor = DS.Color.Shade.shade100
        return attributedString
    }
}

private extension Array where Element == AttachmentDisplayModel {

    var totalSize: Int64 {
        reduce(0) { result, next in
            return result + Int64(next.size)
        }
    }

}

private extension Array where Element == AttachmentDisplayModel {

    var totalSizeDescription: String {
        Formatter.bytesFormatter.string(fromByteCount: totalSize)
    }

}

private extension AttachmentDisplayModel {

    var displaySize: String {
        Formatter.bytesFormatter.string(fromByteCount: Int64(size))
    }

}

#Preview {
    VStack {
        MessageBodyAttachmentsView(
            attachments: .previewData,
            attachmentIDToOpen: .constant(nil)
        )
        Spacer()
    }
}
