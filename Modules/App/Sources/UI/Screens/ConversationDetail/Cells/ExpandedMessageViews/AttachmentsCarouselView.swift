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
import ProtonCoreUI

struct AttachmentsCarouselView: View {
    private let attachments: [AttachmentDisplayModel]

    init(attachments: [AttachmentDisplayModel]) {
        self.attachments = attachments
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.standard) {
                    ForEach(attachments, id: \.self) { attachment in
                        attachmentView(attachment: attachment)
                    }
                }
            }
            .contentMargins(.horizontal, DS.Spacing.large)

            if attachments.count > 2 {
                HStack(spacing: DS.Spacing.small) {
                    Image(DS.Icon.icPaperClip)
                        .resizable()
                        .square(size: 14)
                    Text(attachments.totalSizeDescription)
                        .font(.footnote)
                        .foregroundStyle(DS.Color.Text.weak)
                }.padding(.horizontal, DS.Spacing.large)
            }
        }
    }

    func attachmentView(attachment: AttachmentDisplayModel) -> some View {
        HStack(spacing: DS.Spacing.standard) {
            Image(attachment.mimeType.category.bigIcon)
                .resizable()
                .square(size: 32)
            VStack(alignment: .leading, spacing: DS.Spacing.tiny) {
                Text(attachment.name)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
                Text(attachment.displaySize)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.hint)
            }
        }
        .padding(.all, DS.Spacing.medium)
        .frame(width: 155, alignment: .leading)
        .background(DS.Color.InteractionWeak.norm)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .strokeBorder(DS.Color.Border.strong, lineWidth: 1)
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
    AttachmentsCarouselView(attachments:
        [
            .init(id: .init(value: 1), mimeType: .init(mime: "pdf", category: .pdf), name: "CV", size: 1200),
            .init(id: .init(value: 2), mimeType: .init(mime: "img", category: .image), name: "My photo", size: 12000),
            .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Covering letter", size: 120000),
        ]
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
        "\(count) attachments - \(Formatter.bytesFormatter.string(fromByteCount: totalSize))".notLocalized
    }

}

private extension AttachmentDisplayModel {

    var caption: String {
        [mimeType.mime, displaySize].joined(separator: " ")
    }

    var displaySize: String {
        Formatter.bytesFormatter.string(fromByteCount: Int64(size))
    }

}
