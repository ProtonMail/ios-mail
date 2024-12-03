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
import proton_app_uniffi

struct MessageBodyAttachmentsView: View {
    private let attachments: [AttachmentDisplayModel]
    @State private var isAttachmentsListOpen: Bool = false
    @Binding var attachmentIDToOpen: ID?

    init(attachments: [AttachmentDisplayModel], attachmentIDToOpen: Binding<ID?>) {
        self.attachments = attachments
        self._attachmentIDToOpen = attachmentIDToOpen
    }

    var body: some View {
        if attachments.count > 3 {
            expandableAttachmentsList()
        } else {
            attachmentsList()
        }
    }

    // MARK: - Private

    private func expandableAttachmentsList() -> some View {
        VStack(spacing: DS.Spacing.standard) {
            attachmentsCountRow()
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
            ForEach(attachments, id: \.self) { attachment in
                attachmentButton(attachment: attachment)
            }
        }
    }

    private func attachmentsCountRow() -> some View {
        Button(action: { withAnimation { isAttachmentsListOpen.toggle() } }) {
            HStack(spacing: .zero) {
                Image(DS.Icon.icPaperClip)
                    .resizable()
                    .square(size: 20)
                    .foregroundStyle(DS.Color.Icon.weak)
                    .padding(.trailing, DS.Spacing.medium)
                Text(attachmentsCount)
                Spacer()
                Text(attachments.totalSizeDescription)
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
        .padding(.vertical, DS.Spacing.mediumLight)
        .padding(.leading, DS.Spacing.medium)
        .padding(.trailing, DS.Spacing.large)
        .background(DS.Color.InteractionWeak.norm)
        .clipShape(Capsule())
    }

    private func attachmentButton(attachment: AttachmentDisplayModel) -> some View {
        Button(action: { attachmentIDToOpen = attachment.id }) {
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
            .padding(.vertical, DS.Spacing.mediumLight) // FIXME: - Duplication
            .padding(.leading, DS.Spacing.medium)
            .padding(.trailing, DS.Spacing.large)
            .background(DS.Color.InteractionWeak.norm)
            .clipShape(Capsule())
        }
    }

    private var attachmentsCount: AttributedString {
        var attributedString = AttributedString(localized: L10n.MessageDetails.attachments(count: attachments.count))
        attributedString.font = .footnote
        attributedString.foregroundColor = DS.Color.Text.weak
        let numberRange = attributedString.range(of: "\(attachments.count)").unsafelyUnwrapped
        attributedString[numberRange].font = .system(Font.TextStyle.footnote, weight: .bold)
        attributedString[numberRange].foregroundColor = DS.Color.Shade.shade100
        return attributedString
    }
}

private enum Formatter {
    static let bytesFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter
    }()
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
        MessageBodyAttachmentsView(attachments:
            [
                .init(id: .init(value: 1), mimeType: .init(mime: "pdf", category: .pdf), name: "CV", size: 1200),
                .init(id: .init(value: 2), mimeType: .init(mime: "img", category: .image), name: "My photo", size: 12000),
                .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Covering letter", size: 120000),
                .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Long long long long long long long long long long name", size: 120000),
            ], attachmentIDToOpen: .constant(nil)
        )
        MessageBodyAttachmentsView(attachments:
            [
                .init(id: .init(value: 1), mimeType: .init(mime: "pdf", category: .pdf), name: "CV", size: 1200),
                .init(id: .init(value: 2), mimeType: .init(mime: "img", category: .image), name: "My photo", size: 12000),
                .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Covering letter", size: 120000),
                .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Long long long long long long long long long long name", size: 120000),
            ], attachmentIDToOpen: .constant(nil)
        )
        Spacer()
    }
}
