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
    private let mailbox: Mailbox
    private let attachments: [AttachmentDisplayModel]
    @Binding var attachmentToOpen: AttachmentViewConfig?

    init(attachments: [AttachmentDisplayModel], mailbox: Mailbox, attachmentToOpen: Binding<AttachmentViewConfig?>) {
        self.attachments = attachments
        self.mailbox = mailbox
        self._attachmentToOpen = attachmentToOpen
    }

    var body: some View {
        VStack {
            attachmentsCountRow(attachments: attachments)
//            ForEach(attachments, id: \.self) { attachment in
//                HStack(spacing: DS.Spacing.standard) {
//                    attachmentButton(attachment: attachment)
//                }
//            }
        }
//        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: DS.Spacing.standard) {
//                    ForEach(attachments, id: \.self) { attachment in
//                        attachmentButton(attachment: attachment)
//                    }
//                }
//            }
//            .contentMargins(.horizontal, DS.Spacing.large)
//
//            if attachments.count > 2 {
//                HStack(spacing: DS.Spacing.small) {
//                    Image(DS.Icon.icPaperClip)
//                        .resizable()
//                        .square(size: 14)
//                    Text(attachments.totalSizeDescription)
//                        .font(.footnote)
//                        .foregroundStyle(DS.Color.Text.weak)
//                }.padding(.horizontal, DS.Spacing.large)
//            }
//        }
    }

    // MARK: - Private

    private func attachmentsCountRow(attachments: [AttachmentDisplayModel]) -> some View {
        Button(action: {}) {
            HStack(spacing: .zero) {
                Image(DS.Icon.icPaperClip)
                    .resizable()
                    .square(size: 20)
                    .foregroundStyle(DS.Color.Icon.weak)
                    .padding(.trailing, DS.Spacing.medium)
                Text("\(attachments.count) ")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(DS.Color.Shade.shade100)
                Text("attachments")
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
                Spacer()
                Text(attachments.totalSizeDescription)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
                    .padding(.trailing, DS.Spacing.mediumLight)
                Image(DS.Icon.icChevronTinyUp)
                    .resizable()
                    .square(size: 20)
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
        Button(action: {
            attachmentToOpen = .init(id: attachment.id, mailbox: mailbox)
        }) {
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
            .padding(.vertical, DS.Spacing.mediumLight)
            .padding(.leading, DS.Spacing.medium)
            .padding(.trailing, DS.Spacing.large)
            .background(DS.Color.InteractionWeak.norm)
            .clipShape(Capsule())
        }
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

#Preview {
    MessageBodyAttachmentsView(attachments:
        [
            .init(id: .init(value: 1), mimeType: .init(mime: "pdf", category: .pdf), name: "CV", size: 1200),
            .init(id: .init(value: 2), mimeType: .init(mime: "img", category: .image), name: "My photo", size: 12000),
            .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Covering letter", size: 120000),
            .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Long long long long long long long long long long name", size: 120000),
        ], mailbox: .init(noPointer: .init()), attachmentToOpen: .constant(nil)
    )
}

extension Array where Element == AttachmentDisplayModel {

    var totalSize: Int64 {
        reduce(0) { result, next in
            return result + Int64(next.size)
        }
    }

}

extension Array where Element == AttachmentDisplayModel {

    var totalSizeDescription: String {
        "\(Formatter.bytesFormatter.string(fromByteCount: totalSize))".notLocalized
    }

}

private extension AttachmentDisplayModel {

    var displaySize: String {
        Formatter.bytesFormatter.string(fromByteCount: Int64(size))
    }

}
